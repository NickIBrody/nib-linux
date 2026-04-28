# frozen_string_literal: true

module NIB
  class Recipe
    attr_accessor :name, :version, :summary, :homepage, :build_deps, :runtime_deps, :steps

    def initialize(name)
      @name = name
      @version = "0.0.0"
      @summary = ""
      @homepage = ""
      @build_deps = []
      @runtime_deps = []
      @steps = []
    end
  end

  class RecipeDSL
    attr_reader :recipe

    def initialize(name)
      @recipe = Recipe.new(name)
    end

    def version(value) = @recipe.version = value
    def summary(value) = @recipe.summary = value
    def homepage(value) = @recipe.homepage = value
    def build_dep(*values) = @recipe.build_deps.concat(values.flatten)
    def runtime_dep(*values) = @recipe.runtime_deps.concat(values.flatten)
    def step(value) = @recipe.steps << value
  end

  class RecipeStore
    def self.load_file(path)
      name = File.basename(path, ".rb")
      dsl = RecipeDSL.new(name)
      dsl.instance_eval(File.read(path), path)
      dsl.recipe
    end

    def self.load_dir(dir)
      Dir[File.join(dir, "*.rb")].sort.each_with_object({}) do |path, recipes|
        recipe = load_file(path)
        recipes[recipe.name] = recipe
      end
    end
  end
end
