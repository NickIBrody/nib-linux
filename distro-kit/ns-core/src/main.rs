use anyhow::{anyhow, bail, Context, Result};
use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::ffi::OsStr;
use std::fs::{self, File};
use std::io::Read;
use std::path::{Component, Path, PathBuf};
use tar::{Archive, Builder, EntryType, Header};
use walkdir::WalkDir;

#[derive(Parser)]
#[command(name = "ns-core")]
#[command(about = "NIB package backend written in Rust")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    Pack(PackArgs),
    Index(IndexArgs),
    Install(InstallArgs),
    InstallFile(InstallFileArgs),
    ListRepo(ListRepoArgs),
    Info(InfoArgs),
    ListInstalled(ListInstalledArgs),
}

#[derive(Parser)]
struct PackArgs {
    #[arg(long)]
    name: String,
    #[arg(long)]
    version: String,
    #[arg(long)]
    release: u64,
    #[arg(long)]
    arch: String,
    #[arg(long)]
    summary: String,
    #[arg(long)]
    source: PathBuf,
    #[arg(long)]
    output: PathBuf,
    #[arg(long = "dep")]
    deps: Vec<String>,
}

#[derive(Parser)]
struct IndexArgs {
    #[arg(long)]
    repo_dir: PathBuf,
}

#[derive(Parser)]
struct InstallArgs {
    package: String,
    #[arg(long)]
    repo: PathBuf,
    #[arg(long, default_value = "/")]
    root: PathBuf,
}

#[derive(Parser)]
struct InstallFileArgs {
    package_file: PathBuf,
    #[arg(long, default_value = "/")]
    root: PathBuf,
}

#[derive(Parser)]
struct ListRepoArgs {
    repo: PathBuf,
}

#[derive(Parser)]
struct InfoArgs {
    package: String,
    #[arg(long)]
    repo: PathBuf,
}

#[derive(Parser)]
struct ListInstalledArgs {
    #[arg(long, default_value = "/")]
    root: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct PackageManifest {
    name: String,
    version: String,
    release: u64,
    arch: String,
    summary: String,
    #[serde(default)]
    deps: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RepoEntry {
    name: String,
    version: String,
    release: u64,
    arch: String,
    summary: String,
    deps: Vec<String>,
    archive: String,
    sha256: String,
    size: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct RepoIndex {
    generated_by: String,
    packages: Vec<RepoEntry>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct InstalledRecord {
    manifest: PackageManifest,
    archive: String,
    installed_size: u64,
}

fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.command {
        Command::Pack(args) => pack(args),
        Command::Index(args) => index_repo(args),
        Command::Install(args) => install_from_repo(args),
        Command::InstallFile(args) => install_file(args),
        Command::ListRepo(args) => list_repo(args),
        Command::Info(args) => info(args),
        Command::ListInstalled(args) => list_installed(args),
    }
}

fn pack(args: PackArgs) -> Result<()> {
    if !args.source.is_dir() {
        bail!("source directory {:?} does not exist", args.source);
    }

    if let Some(parent) = args.output.parent() {
        fs::create_dir_all(parent)?;
    }

    let manifest = PackageManifest {
        name: args.name,
        version: args.version,
        release: args.release,
        arch: args.arch,
        summary: args.summary,
        deps: args.deps,
    };

    let file = File::create(&args.output)
        .with_context(|| format!("failed to create {:?}", args.output))?;
    let encoder = zstd::Encoder::new(file, 19)?;
    let mut builder = Builder::new(encoder.auto_finish());

    let manifest_bytes = toml::to_string(&manifest)?.into_bytes();
    let mut header = Header::new_gnu();
    header.set_entry_type(EntryType::Regular);
    header.set_size(manifest_bytes.len() as u64);
    header.set_mode(0o644);
    header.set_cksum();
    builder.append_data(&mut header, ".nib/manifest.toml", manifest_bytes.as_slice())?;

    for entry in WalkDir::new(&args.source) {
        let entry = entry?;
        let path = entry.path();
        if path == args.source {
            continue;
        }

        let rel = path.strip_prefix(&args.source)?;
        let archive_path = Path::new("root").join(rel);

        if entry.file_type().is_dir() {
            builder.append_dir(&archive_path, path)?;
        } else if entry.file_type().is_file() {
            builder.append_path_with_name(path, &archive_path)?;
        } else if entry.file_type().is_symlink() {
            let target = fs::read_link(path)?;
            let mut link_header = Header::new_gnu();
            link_header.set_entry_type(EntryType::Symlink);
            link_header.set_size(0);
            link_header.set_mode(0o777);
            link_header.set_cksum();
            builder.append_link(&mut link_header, &archive_path, target)?;
        }
    }

    builder.finish()?;
    println!("{}", args.output.display());
    Ok(())
}

fn index_repo(args: IndexArgs) -> Result<()> {
    let packages_dir = args.repo_dir.join("packages");
    fs::create_dir_all(&packages_dir)?;

    let mut packages = Vec::new();
    for entry in fs::read_dir(&packages_dir)? {
        let entry = entry?;
        let path = entry.path();
        if path.extension() != Some(OsStr::new("nib")) {
            continue;
        }

        let manifest = read_manifest_from_package(&path)?;
        let archive_name = path
            .strip_prefix(&args.repo_dir)?
            .to_string_lossy()
            .replace('\\', "/");
        let sha256 = sha256_file(&path)?;
        let size = fs::metadata(&path)?.len();

        packages.push(RepoEntry {
            name: manifest.name,
            version: manifest.version,
            release: manifest.release,
            arch: manifest.arch,
            summary: manifest.summary,
            deps: manifest.deps,
            archive: archive_name,
            sha256,
            size,
        });
    }

    packages.sort_by(|a, b| a.name.cmp(&b.name).then(a.version.cmp(&b.version)));
    let index = RepoIndex {
        generated_by: "ns-core 0.1.0".to_string(),
        packages,
    };

    let index_path = args.repo_dir.join("index.json");
    let json = serde_json::to_vec_pretty(&index)?;
    fs::write(&index_path, json)?;
    println!("{}", index_path.display());
    Ok(())
}

fn install_from_repo(args: InstallArgs) -> Result<()> {
    let index = load_index(&args.repo)?;
    let entry = index
        .packages
        .iter()
        .find(|pkg| pkg.name == args.package)
        .cloned()
        .ok_or_else(|| anyhow!("package {} not found in {}", args.package, args.repo.display()))?;

    let package_path = args.repo.join(&entry.archive);
    let actual = sha256_file(&package_path)?;
    if actual != entry.sha256 {
        bail!(
            "sha256 mismatch for {}: expected {}, got {}",
            package_path.display(),
            entry.sha256,
            actual
        );
    }

    install_package_file(&package_path, &args.root, Some(entry.archive))
}

fn install_file(args: InstallFileArgs) -> Result<()> {
    install_package_file(&args.package_file, &args.root, None)
}

fn list_repo(args: ListRepoArgs) -> Result<()> {
    let index = load_index(&args.repo)?;
    for pkg in index.packages {
        println!(
            "{} {}-{} [{}] :: {}",
            pkg.name, pkg.version, pkg.release, pkg.arch, pkg.summary
        );
    }
    Ok(())
}

fn info(args: InfoArgs) -> Result<()> {
    let index = load_index(&args.repo)?;
    let pkg = index
        .packages
        .into_iter()
        .find(|pkg| pkg.name == args.package)
        .ok_or_else(|| anyhow!("package {} not found", args.package))?;

    println!("name: {}", pkg.name);
    println!("version: {}", pkg.version);
    println!("release: {}", pkg.release);
    println!("arch: {}", pkg.arch);
    println!("summary: {}", pkg.summary);
    println!("archive: {}", pkg.archive);
    println!("sha256: {}", pkg.sha256);
    println!("size: {}", pkg.size);
    println!(
        "deps: {}",
        if pkg.deps.is_empty() {
            "(none)".to_string()
        } else {
            pkg.deps.join(", ")
        }
    );
    Ok(())
}

fn list_installed(args: ListInstalledArgs) -> Result<()> {
    let db_dir = args.root.join("var/lib/nib/db");
    if !db_dir.exists() {
        return Ok(());
    }

    let mut records = Vec::new();
    for entry in fs::read_dir(&db_dir)? {
        let path = entry?.path();
        if path.extension() != Some(OsStr::new("json")) {
            continue;
        }
        let data = fs::read(&path)?;
        let record: InstalledRecord = serde_json::from_slice(&data)?;
        records.push(record);
    }

    records.sort_by(|a, b| a.manifest.name.cmp(&b.manifest.name));
    for record in records {
        println!(
            "{} {}-{} [{}]",
            record.manifest.name, record.manifest.version, record.manifest.release, record.manifest.arch
        );
    }
    Ok(())
}

fn install_package_file(package_path: &Path, root: &Path, archive_name: Option<String>) -> Result<()> {
    fs::create_dir_all(root)?;
    let manifest = read_manifest_from_package(package_path)?;

    let file = File::open(package_path)?;
    let decoder = zstd::Decoder::new(file)?;
    let mut archive = Archive::new(decoder);
    let mut installed_size = 0u64;

    for entry in archive.entries()? {
        let mut entry = entry?;
        let path = entry.path()?.into_owned();
        if !path.starts_with("root") {
            continue;
        }

        let rel = path.strip_prefix("root")?;
        if rel.as_os_str().is_empty() {
            continue;
        }
        let safe = sanitize_rel_path(rel)?;
        let dest = root.join(&safe);

        if let Some(parent) = dest.parent() {
            fs::create_dir_all(parent)?;
        }

        if entry.header().entry_type().is_dir() {
            fs::create_dir_all(&dest)?;
            continue;
        }

        entry.unpack(&dest)?;
        if let Ok(meta) = fs::metadata(&dest) {
            installed_size += meta.len();
        }
    }

    let db_dir = root.join("var/lib/nib/db");
    fs::create_dir_all(&db_dir)?;
    let record = InstalledRecord {
        manifest: manifest.clone(),
        archive: archive_name.unwrap_or_else(|| package_path.display().to_string()),
        installed_size,
    };
    let record_path = db_dir.join(format!("{}.json", manifest.name));
    fs::write(record_path, serde_json::to_vec_pretty(&record)?)?;

    println!(
        "installed {} {}-{} into {}",
        manifest.name,
        manifest.version,
        manifest.release,
        root.display()
    );
    Ok(())
}

fn load_index(repo: &Path) -> Result<RepoIndex> {
    let data = fs::read(repo.join("index.json"))
        .with_context(|| format!("failed to read repo index in {}", repo.display()))?;
    Ok(serde_json::from_slice(&data)?)
}

fn read_manifest_from_package(path: &Path) -> Result<PackageManifest> {
    let file = File::open(path)?;
    let decoder = zstd::Decoder::new(file)?;
    let mut archive = Archive::new(decoder);

    for entry in archive.entries()? {
        let mut entry = entry?;
        let entry_path = entry.path()?.into_owned();
        if entry_path == Path::new(".nib/manifest.toml") {
            let mut buf = Vec::new();
            entry.read_to_end(&mut buf)?;
            let manifest: PackageManifest = toml::from_str(std::str::from_utf8(&buf)?)?;
            return Ok(manifest);
        }
    }

    bail!("manifest not found in {}", path.display())
}

fn sha256_file(path: &Path) -> Result<String> {
    let mut file = File::open(path)?;
    let mut hasher = Sha256::new();
    let mut buf = [0u8; 8192];
    loop {
        let n = file.read(&mut buf)?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

fn sanitize_rel_path(path: &Path) -> Result<PathBuf> {
    let mut clean = PathBuf::new();
    for component in path.components() {
        match component {
            Component::Normal(part) => clean.push(part),
            Component::CurDir => {}
            Component::ParentDir | Component::RootDir | Component::Prefix(_) => {
                bail!("unsafe path in package archive: {}", path.display())
            }
        }
    }

    if clean.as_os_str().is_empty() {
        bail!("empty install path in package archive");
    }
    Ok(clean)
}
