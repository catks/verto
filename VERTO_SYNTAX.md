# Verto Syntax

## verto_version

Set the minimal verto version compatible with Vertofile

```ruby
# Vertofile
verto_version '0.11.0'
```

## config

Allows you to  customize the behavior for verto commands.

Example:
```ruby
# Vertofile
config {
 version.prefix = 'v' # Adds a version_prefix
 pre_release.default_identifier = 'alpha' # Defaults to 'rc'
 git.pull_before_tag_creation = true # Pull Changes before tag creation
 git.fetch_before_tag_creation = true # Fetch Branches and Tags before tag creation
 git.push_after_tag_creation = true # Push changes after tag creation

 ## CHANGELOG FORMAT
 ## Verto uses Mustache template rendering to render changelog updates, the default value is:
 ##
 ##   ## {{new_version}} - #{Time.now.strftime('%d/%m/%Y')}
 ##       {{#version_changes}}
 ##       * {{.}}
 ##       {{/version_changes}}
 ##
 ## A custom format can be specified, eg:
 changelog.format =  <<~CHANGELOG
                        ## {{new_version}}
                         {{#version_changes}}
                         * {{.}}
                         {{/version_changes}}
                     CHANGELOG
}

```

## context

In the context block you can create a scope that will only run if the statment it's true.

Example:

```ruby
# Vertofile

# Only runs on master branch
context(branch('master')) {
...
}

# Only runs on staging branch
context(branch('staging')) {
...
}
# Only runs if the branch is not master or staging
context(!branch('master', 'staging')) {
...
}

# You can also run with a custom conditional (With ruby code)
context(current_branch.match?(/feature\/.+/)) {
...
}
```

## before

Runs before executing a verto command

```ruby
# Vertofile

before {
 puts "Before a command"
}
context(branch('master')) {
	before {
	 puts "Before a command in master branch"
	}
}
```
## after
Runs after executing a verto command

Example:
```ruby
# Vertofile

after {
 puts "After a command"
}
context(branch('master')) {
	before {
	 puts "After a command in master branch"
	}
}
```

## before_command_tag_up

Almost the same as before but run before the tag creation, the new tag can be accessible with as `new_version`

Example:
```ruby
# Vertofile

before_tag_creation {
     puts "New version is #{new_version}"
     ...
}
```

## after_command_tag_up

The same as before_command_tag_up but run after the tag creation, the new tag can be accessible with as `new_version`

Example:
```ruby
# Vertofile

after_tag_creation {
     puts "New version is #{new_version}"
     ...
}
```

## command_options

Allows you to set a specific option without the need to pass it explicity in the verto command (See `verto tag up --help` to see the options).

Example:
```ruby
# Vertofile

context(branch('master')) {
  before_command_tag_up {
    command_options.add(filter: 'release_only')
  }
  ...
}

context(branch('staging')) {
  before_command_tag_up {
    command_options.add(pre_release: 'rc')
  }
  ...
}
```

## update_changelog

Start a flow to update the changelog (must be in `before_command_tag_up` or  `after_command_tag_up)`

Options include:

* `:merged_pull_requests_with_bracketed_labels`: Uses all PR merged commits after the last tag if they have the [***] pattern
* `:commits_with_bracketed_labels` : Uses all commits after the last tag if they have the [***] pattern (Exclude merge commits)
* `:merged_pull_requests_messages` : Uses all merged commit after the last tag
* `:commit_messages`: Uses all commits after the last tag (Exclude merge commits)

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
     update_changelog(with: :merged_pull_requests_with_bracketed_labels,
                      confirmation: true, # Asks for confirmation (you can also edit the generated CHANGELOG)
                      filename: 'CHANGELOG.md')
     git('add CHANGELOG.md')

     git('commit -m "Updates CHANGELOG"')
  }
}
...
```

## file

Allows you to do some operations in a specific file.

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
      file('package.json').replace(/"(\d+)\.(\d+)\.(\d+)(-?.*)"/, %Q{"#{new_version}"})
      git!('add package.json')

      file('README.md').replace_all(latest_version.to_s, new_version.to_s)
      git!('add README.md')
      git!('commit -m "Bumps Version"')

	  file('versions_asc').append("#{new_version} - #{Time.now}")
	  file('versions_desc').prepend("#{new_version} - #{Time.now}")
    }
  }
...
```

## env

Allows you to access a specifc environment variable

Example:
```ruby
# Vertofile
...
context(branch('staging')) {
  before_tag_creation {
	  file('ci.log').append(env('CI_WORKER'))
	  ...
    }
  }
...
```

## confirm

Ask for confirmation before executing anything

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
	  confirm('Are you sure?')
	  ...
    }
  }
...
```

## error

Sends an error to **stderr**

Example:
```ruby
# Vertofile
...
context(!branch('master')) {
   error('Not at master')
}
...
```

## error!

The same as error but exits verto (without creating a tag)

Example:
```ruby
# Vertofile
...
context(!branch('master')) {
   error!('Not at master')
}
...
```

## sh

Runs any shell command.

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
      ...
      sh('bundle install')
      sh('rake install')
      git!('add Gemfile.lock')

      git!('commit -m "Bumps Version"')
    }
  }
...
```

## sh!

The same as sh but exits verto in case of errors

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
      ...
      sh!('bundle install')
      sh!('rake install')
      git!('add Gemfile.lock')

      git!('commit -m "Bumps Version"')
    }
  }
...
```

## git

Runs git commands in verto

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
      ...
      update_changelog
      git('add CHANGELOG.md')
      git('commit -m "Bumps Version"')
    }
  }
...
```

## git!

The same as **git** but exits verto in case of errors

Example:
```ruby
# Vertofile
...
context(branch('master')) {
  before_tag_creation {
      ...
      update_changelog
      git!('add CHANGELOG.md')
      git!('commit -m "Bumps Version"')
    }
  }
...
```
