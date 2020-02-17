# Verto

Verto is a CLI to generate git tags (following the [Semantic Versioning](https://semver.org/) system)

## Installation

### Docker Image(Recommended)

You don't need to install verto in your machine, you can run verto via the docker image

To use verto in the same way that will be used as any other cli in your machine, you can set an alias in your `.bashrc`, `.zshrc`, etc:

```
alias verto='docker run -v $(pwd):/usr/src/project -it catks/verto'
```

Now you can run any verto command! :)

### Ruby Gem
Verto is distributed as a ruby gem, to install run:

```
$ gem install verto
```

## Usage

Now you can run verto right out of the box without any configuration:

```
  verto tag up --patch # Creates a new tag increasing the patch number
  verto tag up --minor # Creates a new tag increasing the minor number
  verto tag up --major # Creates a new tag increasing the major number
```

### Verto DSL

If you need a more specific configuration or want to reflect your development proccess in some way, you can use Verto DSL creating a Vertofile with the configuration.

```ruby
# Vertofile
config {
  pre_release.initial_number = 0
  project.path = "my/repo/path"
}

before { sh('echo "Creating Tag"') }

context(branch('master')) {
  on('before_tag_creation') {
    versions_changes = "## #{new_version} - #{Time.now.strftime('%d/%m/%Y')}\n"
    exit unless confirm("Create a new release?\n" \
      "#{versions_changes}"
    )

    file('CHANGELOG.md').prepend(versions_changes)
    git('add CHANGELOG.md')
    git('commit -m "Updates CHANGELOG"')
  }

  after_command('tag_up') {
    git('push --tags')
    git('push origin master')
  }
}

context(branch('qa')) {
  before_command('tag_up') {
    command_options.add(pre_release: 'rc')
  }

  after_command('tag_up') {
    file('releases.log').append(new_version.to_s)
  }
}

```

#### Verto Syntax

...TODO...

## TODO

  1. Complete README.md description
  2. Add a configuration to enable, disable or specify the number of tags that a single commit can have(eg: only one release and one pre-release)
  3. Enable the *sh* dsl output to be show as default

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/verto.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
