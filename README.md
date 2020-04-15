# Verto
[![Build Status](https://travis-ci.org/catks/verto.svg?branch=master)](https://travis-ci.org/catks/verto)
[![Maintainability](https://api.codeclimate.com/v1/badges/b699d13df33e33bbe2d0/maintainability)](https://codeclimate.com/github/catks/verto/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/39e7c6f1f5f57b8555ed/test_coverage)](https://codeclimate.com/github/catks/verto/test_coverage)\
Verto is a CLI to generate git tags (following the [Semantic Versioning](https://semver.org/) system)

## Installation


### Ruby Gem
Verto is distributed as a ruby gem, to install run:

```shell
$ gem install verto
```

### With Rbenv

If you use Rbenv you can install verto only once and create a alias in your .basrc, .zshrc, etc:

#### ZSH
    $ RBENV_VERSION=$(rbenv global) gem install verto && echo "alias verto='RBENV_VERSION=$(rbenv global) verto'" >> ~/.zshrc

#### Bash
    $ RBENV_VERSION=$(rbenv global) gem install verto && echo "alias verto='RBENV_VERSION=$(rbenv global) verto'" >> ~/.bashrc


### Docker Image

You don't need to install verto in your machine, you can run verto via the docker image

To use verto in the same way that you use any other cli, you can set an alias in your `.bashrc`, `.zshrc`, etc:

```shell
alias verto='docker run -v $(pwd):/usr/src/project -it catks/verto:0.5.0'
```

If you want you can share your git configuration and known_hosts with:

```shell
alias verto='docker run -v ~/.gitconfig:/etc/gitconfig -v $(pwd):/usr/src/project -v $HOME/.ssh/known_hosts:/root/.ssh/known_hosts -it catks/verto:0.5.0'

```

You can also use your ssh keys with verto container (for git push):

```shell
alias verto='docker run -v $(pwd):/usr/src/project -v $HOME/.ssh/known_hosts:/root/.ssh/known_hosts -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa -e SSH_PRIVATE_KEY=/root/.ssh/id_rsa -it catks/verto:0.5.0'

```

Or share the git config, known_hosts and ssh_keys:


```shell
alias verto='docker run -v ~/.gitconfig:/etc/gitconfig -v $(pwd):/usr/src/project -v $HOME/.ssh/known_hosts:/root/.ssh/known_hosts -v $HOME/.ssh/id_rsa:/root/.ssh/id_rsa -e SSH_PRIVATE_KEY=/root/.ssh/id_rsa -it catks/verto:0.5.0'

```

Now you can run any verto command! :)

## Usage

You can run verto right out of the box without any configuration:

```shell
  verto tag up --patch # Creates a new tag increasing the patch number
  verto tag up --minor # Creates a new tag increasing the minor number
  verto tag up --major # Creates a new tag increasing the major number

  # You can also work with pre release identifiers
  verto tag up --major --pre_release=rc # Creates a new tag increasing the major number and adding the rc identifier
  verto tag up --pre_release=rc # Creates a new tag increasing the pre_release number, eg: rc.1 to rc.2

  # Or ensure that a release tag will be created, eg: with a last tag 1.1.1-rc.1

  verto tag up --release # Creates a 1.1.1 tag

  # You can filter the tags you want to consider for increasing

  verto tag up --patch --filter=release_only # For Realease Tags Only
  verto tag up --patch --filter=pre_release_only # For Pre Realease Tags Only
  verto tag up --patch --filter='\d+\.\d+\.\d+-alpha.*' # Custom Regexp!

```

### Verto DSL

If you need a more specific configuration or want to reflect your development proccess in some way, you can use Verto DSL creating a Vertofile with the configuration.

You can create a new Vertofile with `verto init` or following the next example:

```ruby
# Vertofile

verto_version '0.5.0'

config {
 # version.prefix = 'v' # Adds a version_prefix
}

context(branch('master')) {
  before_command('tag_up') {
    git!('origin master')
    command_options.add(filter: 'release_only')
  }

  on('before_tag_creation') {

    version_changes = ""
    bitbucket_changes = sh(
      %q#git log --oneline --decorate  | grep -B 100 -m 1 "tag:" | grep "pull request" | awk '{print $1}' | xargs git show --format='%b' | grep -v Approved | grep -v "^$" | grep -E "^[[:space:]]*\[.*\]" | sed 's/^[[:space:]]*\(.*\)/ * \1/'#, output: false
    ).output
    version_changes = bitbucket_changes


    puts "---------------------------"
    version_changes = "## #{new_version} - #{Time.now.strftime('%d/%m/%Y')}\n#{version_changes}\n"
    exit unless confirm("Create new Realease?\n" \
      "---------------------------\n" \
      "#{version_changes}" \
      "---------------------------\n"
    )

    # CHANGELOG
    file('CHANGELOG.md').prepend(version_changes)
    git('add CHANGELOG.md')

    # Uncomment to update the version in other files, like package.json
    # file('package.json').replace(/"(\d+)\.(\d+)\.(\d+)(-?.*)"/, %Q{"#{new_version}"})
    # git('add package.json')

    git('commit -m "Updates CHANGELOG"')
  }

  after_command('tag_up') {
    git('push --tags')
    git('push origin master')
  }
}

 context(branch('staging')) {
  before_command('tag_up') {
    git!('pull origin staging')
    command_options.add(pre_release: 'rc')
  }

  on('before_tag_creation') {
    # file('package.json').replace(/"(\d+)\.(\d+)\.(\d+)(-?.*)"/, %Q{"#{new_version}"})
    # git('add package.json')

    git('commit -m "Release QA"')
    git('commit --allow-empty -m "Staging Release"')
  }

  after_command('tag_up') {
    git('push --tags')
    git('push origin staging')
  }
}

# Block tag creation in other branchs
context(!branch('master', 'staging')) {
  error "Tags only can be created in master or staging branch"
  exit
}
```

#### Verto Syntax

...TODO...

## TODO

  1. Complete README.md description
  2. Add a configuration to enable, disable or specify the number of tags that a single commit can have(eg: only one release and one pre-release)
  5. Adds more specs and test coverage in CI

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/catks/verto.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
