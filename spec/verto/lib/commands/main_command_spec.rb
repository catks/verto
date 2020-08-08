require 'stringio'

RSpec.describe Verto::MainCommand do
  before do
    Verto.config.project.path = Verto.root_path.join('tmp/test_repo/').to_s
    # TODO: Remove set in the global variables
    $stderr = stderr
    $stdout = stdout
    allow(Verto).to receive(:stdout).and_return(stdout)
    allow(Verto).to receive(:stderr).and_return(stderr)
  end

  let(:repo) { TestRepo.new }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  around(:each) do |ex|
    begin
      ex.run
    rescue SystemExit => e
      puts e

      raise "Command exits in error #{e.message}"
    end
  end

  after do
    repo.clear!
    # TODO: Create a config reload! to get defaults
    Verto.config.command_options = Verto::CommandOptions.new
    Verto.config.version.prefix = ''
    Verto.config.hooks = []
    Verto.config.version.validations.new_version_must_be_bigger = true
    Verto.config.git.pull_before_tag_creation = false
    Verto.config.git.push_after_tag_creation = false
  end

  describe 'init' do
    subject(:init) { described_class.start(['init'] + options) }
    let(:options) { [] }
    let(:project_path) { Pathname.new(Verto.config.project.path) }

    context 'when Vertofile doesnt exists' do
      it 'creates a Vertofile' do
        expect { init }.to change { project_path.join('Vertofile').exist? }.from(false).to(true)
      end
    end

    context 'when Vertofile exists' do
      before { repo.run 'touch Vertofile'}

      it 'exits on error' do
        expect { init }.to raise_error(SystemExit) do |error|
          expect(stderr.string).to eq(
            <<~TEXT
                Project already have a Vertofile.
                If you want to generate a new with verto init, delete the current one with: `rm Vertofile`
            TEXT
          )
        end
      end
    end
  end

  describe 'version' do
    subject(:version) { described_class.start(['version']) }

    it 'shows the verto version' do
      version

      expect(stdout.string).to eq("#{Verto::VERSION}\n")
    end
  end

  # TODO: Move to a tag_command specfile
  describe 'tag' do
    describe 'up' do
      subject(:up) { described_class.start(['tag','up'] + options ) }

      let(:options) { [] }
      let(:vertofile) { nil }
      let(:command_executor) { Verto::SystemCommandExecutor.new }

      before do
        allow(Verto::SystemCommandExecutor).to receive(:new).and_return(command_executor)

        Verto::DSL::Interpreter.new.evaluate(vertofile) if vertofile
      end

      context 'when the repository doesnt have a previous tag' do
        before do
          repo.reload!
        end

        let(:options) { ['--patch'] }

        it 'dont create a tag' do
          expect { up }.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
            result = repo.run('git log --decorate HEAD')
            expect(result).to_not include('tag:')
          end
        end

        it 'exits on error' do
          expect { up }.to raise_error(SystemExit) do |error|
            expect(stderr.string).to eq(
              <<~TEXT
                Project doesn't have a previous tag version, create a new tag with git.
                eg: `git tag 0.1.0`
              TEXT
            )
          end
        end
      end

      context 'with a lastest tag' do
        before do
          repo.reload!
          repo.run("git tag #{older_tag}") if older_tag
          repo.commit!('Second')
          repo.run("git tag #{last_tag}")
          repo.commit!('Third')
        end

        let(:older_tag) { nil }

        context 'without a version option' do
          let(:last_tag) { '2.0.0' }

          it 'dont create a tag' do
            expect { up }.to raise_error(SystemExit) do |error|
              expect(error.status).to eq(1)
              result = repo.run('git log --decorate -n 1 HEAD')
              expect(result).to_not include('tag:')
            end
          end

          it 'exits on error' do
            expect { up }.to raise_error(SystemExit) do |error|
              expect(stderr.string).to eq(
                <<~TEXT
                You must specify the version number to be increased, use the some of the options(eg: --major, --minor, --patch, --pre_release=rc)
                or configure a Vertofile to specify a default option for current context, eg:

                context('qa') {
                  before_command('tag_up') {
                    command_options.add(pre_release: 'rc')
                  }
                }
                TEXT
              )
            end
          end
        end

        context 'with --patch option' do
          let(:options) { ['--patch'] }
          let(:last_tag) { '1.0.19' }

          it 'create a tag with the patch number increased' do
            up

            result = repo.run('git log --decorate HEAD')
            expect(result).to include('tag: 1.0.20')
          end

          it 'shows the created tag in stderr' do
            up

            expect(stderr.string).to eq(
              <<~TEXT
              Creating Tag 1.0.20...
              Tag 1.0.20 Created!
              TEXT
            )
          end

          context 'when Vertofile have a command_add option' do
            let(:vertofile) do
              <<~VERTOFILE
                  command_options.add(pre_release: 'rc')
              VERTOFILE
            end

            it 'create a tag with the patch number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.0.20-rc.1')
            end
          end

          context 'when Vertofile have a command_add option on before hook' do
            let(:vertofile) do
              <<~VERTOFILE
                before {
                  command_options.add(pre_release: 'rc')
                }
              VERTOFILE
            end

            it 'create a tag with the patch number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.0.20-rc.1')
            end
          end

          context 'when Vertofile has a prefix configured' do
            let(:vertofile) do
              <<~VERTOFILE
                  config { version.prefix = 'v' }
              VERTOFILE
            end

            let(:last_tag) { 'v1.0.19' }

            it 'create a tag with a prefix and with the patch number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: v1.0.20')
            end

            context 'but have a version_prefix option' do
              let(:options) { ['--patch', '--version_prefix=V'] }

              it 'create a tag with the prefix in tag up and with the patch number increased' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: V1.0.20')
              end
            end
          end

          context 'when Vertofile has git config options' do
            let(:vertofile) do
              <<~VERTOFILE
                config {
                  git.pull_before_tag_creation = true
                  git.push_after_tag_creation = true
                }
              VERTOFILE
            end

            let(:last_tag) { '10.0.9' }

            before do
              allow(Verto::DSL::BuiltInHooks::GitPullCurrentBranch).to receive(:call)
              allow(Verto::DSL::BuiltInHooks::GitPushCurrentBranch).to receive(:call)
            end

            it 'create a tag' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 10.0.10')
            end

            it 'pulls changes before creating a tag' do
              up

              expect(Verto.config.hooks.select { |h| h.moment == :before }.first).to eq(Verto::DSL::BuiltInHooks::GitPullCurrentBranch)
              expect(Verto::DSL::BuiltInHooks::GitPullCurrentBranch).to have_received(:call)
            end

            it 'push changes after creating a tag' do
              up

              expect(Verto.config.hooks.select { |h| h.moment == :after }.first).to eq(Verto::DSL::BuiltInHooks::GitPushCurrentBranch)
              expect(Verto::DSL::BuiltInHooks::GitPushCurrentBranch).to have_received(:call)
            end
          end

          context 'with a version_prefix option' do
            let(:options) { ['--patch', '--version_prefix=v'] }

            it 'create a tag with the prefix in tag up and with the patch number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: v1.0.20')
            end
          end

          context 'when the latest tag is a pre_release' do
            let(:last_tag) { '1.9.19-rc.10' }

            it 'create a tag with the patch number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.9.20-rc.1')
            end

            context 'but have a filter for release tags' do
              let(:older_tag) { '0.0.1' }
              let(:last_tag) { '0.0.2-rc.1' }
              let(:options) { ['--patch', '--filter=release_only'] }

              it 'create a release tag with the patch number increased' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 0.0.2)')
              end
            end

            context 'but have a --release option' do
              let(:older_tag) { '0.0.1' }
              let(:last_tag) { '0.0.2-rc.1' }
              let(:options) { ['--patch', '--release'] }

              it 'create a release tag with the patch number increased' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 0.0.3)')
              end
            end

            context 'and with a --pre_release' do
              let(:options) { ['--patch', '--pre_release=rc'] }
              let(:last_tag) { '1.9.19-rc.1' }

              it 'upgrades only the patch number' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 1.9.20-rc.1)')
              end

              context 'without the identifier' do
                let(:options) { ['--patch', '--pre_release'] }
                let(:last_tag) { '1.9.19-rc.1' }

                it 'upgrades only the patch number' do
                  up

                  result = repo.run('git log --decorate HEAD')
                  expect(result).to include('tag: 1.9.20-rc.1)')
                end
              end
            end
          end
        end

        context 'with --minor option' do
          let(:options) { ['--minor'] }
          let(:last_tag) { '1.9.19' }

          it 'create a tag with the minor number increased' do
            up

            result = repo.run('git log --decorate HEAD')
            expect(result).to include('tag: 1.10.0')
          end

          context 'when the latest tag is a pre_release' do
            let(:last_tag) { '1.9.19-rc.10' }

            it 'create a tag with the minor number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.10.0-rc.1')
            end
          end

          context 'and with a minor' do
            let(:options) { ['--minor', '--patch'] }
            let(:last_tag) { '1.9.19' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.10.0)')
            end
          end

          context 'and with a --patch' do
            let(:options) { ['--minor', '--patch'] }
            let(:last_tag) { '1.9.19-rc.1' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.10.0-rc.1)')
            end
          end

          context 'and with a --pre_release' do
            let(:options) { ['--minor', '--pre_release=rc'] }
            let(:last_tag) { '1.9.19-rc.1' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.10.0-rc.1)')
            end
          end
        end

        context 'with --major option' do
          let(:options) { ['--major'] }
          let(:last_tag) { '1.9.19' }

          it 'create a tag with the major number increased' do
            up

            result = repo.run('git log --decorate HEAD')
            expect(result).to include('tag: 2.0.0')
          end

          context 'when the latest tag is a pre_release' do
            let(:last_tag) { '1.9.19-rc.10' }

            it 'create a tag with the major number increased' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 2.0.0-rc.1')
            end
          end

          context 'and with a --minor' do
            let(:options) { ['--major', '--minor'] }
            let(:last_tag) { '1.9.19-rc.1' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 2.0.0-rc.1)')
            end
          end

          context 'and with a --patch' do
            let(:options) { ['--major', '--patch'] }
            let(:last_tag) { '1.9.19-rc.1' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 2.0.0-rc.1)')
            end
          end

          context 'and with a --pre_release' do
            let(:options) { ['--major', '--pre_release=rc'] }
            let(:last_tag) { '1.9.19-rc.1' }

            it 'upgrades only the minor number' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 2.0.0-rc.1)')
            end
          end

        end

        context 'with --pre-release option' do
          context 'when not specifying the identifier' do
            let(:options) { ['--pre-release'] }


            context 'when the latest tag is a pre_release' do
              let(:last_tag) { '1.9.19-rc.9' }

              it 'create a tag with the pre_release number increased and the default identifier' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 1.9.19-rc.10')
              end
            end

            context 'when the latest tag isnt a pre_release' do
              let(:last_tag) { '1.9.19' }

              context 'with other incrementer' do
                let(:options) { ['--patch', '--pre-release'] }

                it 'create a tag with the pre_release number increased and the default identifier' do
                  up

                  result = repo.run('git log --decorate HEAD')
                  expect(result).to include('tag: 1.9.20-rc.1')
                end

                context 'with a custom default identifier' do
                  let(:vertofile) do
                    <<~VERTOFILE
                      config { pre_release.default_identifier = 'alpha' }
                    VERTOFILE
                  end

                  it 'create a tag with the pre_release number increased and the default custom identifier' do
                    up

                    result = repo.run('git log --decorate HEAD')
                    expect(result).to include('tag: 1.9.20-alpha.1')
                  end
                end
              end
            end
          end

          context 'when specifying the identifier' do
            let(:options) { ['--pre-release=rc'] }


            context 'when the latest tag is a pre_release' do
              let(:last_tag) { '1.9.19-rc.19' }

              it 'create a tag with the pre_release number increased' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 1.9.19-rc.20')
              end
            end

            context 'when the latest tag isnt a pre_release' do
              let(:last_tag) { '1.9.19' }

              it 'dont create a tag' do
                expect { up }.to raise_error(SystemExit) do |error|
                  expect(error.status).to eq(1)
                  result = repo.run('git log --decorate HEAD')
                  expect(result).to_not include('tag: 1.9.19-rc.1')
                end
              end

              it 'exits on error' do
                expect { up }.to raise_error(SystemExit) do |error|
                  expect(stderr.string).to eq(
                    <<~TEXT
                      New version(1.9.19-rc.1) can't be equal or lower than latest version(#{last_tag})
                      run up --pre-release with --patch, --minor or --major (eg: verto tag up --patch --pre-release=rc),
                      add filters (eg: verto tag up --pre-release --filter=pre_release_only)
                      or disable tag validation in Vertofile with config.version.validations.new_version_must_be_bigger = false
                    TEXT
                  )
                end
              end

              context 'but have a config disabling version validation' do
                let(:vertofile) do
                  <<~VERTOFILE
                    config {
                      version.validations.new_version_must_be_bigger = false
                    }
                  VERTOFILE
                end

                it 'create a tag with the pre_release number increased' do
                  up

                  result = repo.run('git log --decorate HEAD')
                  expect(result).to include('tag: 1.9.19-rc.1')
                end
              end
            end

            context 'when the latest tag is a pre_release with a diferent identifier' do
              let(:last_tag) { '1.9.19-alpha.19' }

              it 'create a tag with the pre_release identifier and the initial value' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 1.9.19-rc.1')
              end
            end
          end
        end

        context 'with a --release option' do
          let(:options) { ['--release'] }

          context 'and last tag is a pre_release' do
            let(:last_tag) { '1.9.19-rc.1' }

            it 'create a release tag' do
              up

              result = repo.run('git log --decorate HEAD')
              expect(result).to include('tag: 1.9.19')
            end
          end
        end
      end
    end
  end
end
