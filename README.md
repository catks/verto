# Verto

Verto is a CLI to generate git tags (following the [Semantic Versioning](https://semver.org/) system)

## Installation


### Ruby Gem
Verto is distributed as a ruby gem, to install run:

```
$ gem install verto
```


### Docker Image

You don't need to install verto in your machine, you can run verto via the docker image

To use verto in the same way that you use any other cli, you can set an alias in your `.bashrc`, `.zshrc`, etc:

```
alias verto='docker run -v $(pwd):/usr/src/project -it catks/verto'
```

If you want to use your ssh keys with verto container (for git push) you can set the alias sharing the ssh key file:

```
alias verto='docker run -v $(pwd):/usr/src/project -v $HOME/.ssh/known_hosts:/root/.ssh/known_hosts -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa -e SSH_PRIVATE_KEY=/root/.ssh/id_rsa -it catks/verto'

```

Now you can run any verto command! :)

## Usage

You can run verto right out of the box without any configuration:

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
    version_changes = "## #{new_version} - #{Time.now.strftime('%d/%m/%Y')}\n"
    exit unless confirm("Create a new release?\n" \
      "#{version_changes}"
    )

    file('CHANGELOG.md').prepend(version_changes)
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

context(branch(/feature.+/)) {
  error "Can't create tags in feature branchs"
}

```

#### Verto Syntax

...TODO...

## TODO

  1. Complete README.md description
  2. Add a configuration to enable, disable or specify the number of tags that a single commit can have(eg: only one release and one pre-release)
  3. Configure tag prefix (eg: 'v' to generate v0.1.0)
  4. Improve DSL Syntax Errors Messages(Ruby backtrace is printed currently)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/verto.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
