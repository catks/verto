require 'stringio'

RSpec.describe Verto::MainCommand do
  before do
    Verto.config.project.path = Verto.root_path.join('tmp/test_repo/').to_s
    $stderr = stderr
  end

  let(:repo) { TestRepo.new }
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
  end

  describe 'tag' do
    describe 'up' do
      subject(:up) { described_class.start(['tag','up'] + options ) }

      let(:options) { [] }

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
        end

        context 'with --pre-release option' do
          context 'when not specifying the identifier' do
            let(:options) { ['--pre-release'] }


            context 'when the latest tag is a pre_release' do
              let(:last_tag) { '1.9.19-rc.19' }

              it 'create a tag with the pre_release number increased and the default identifier' do
                up

                result = repo.run('git log --decorate HEAD')
                expect(result).to include('tag: 1.9.19-rc.20')
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
                      run up --pre-release with --patch, --minor or --major (eg: verto tag up --pre-release --patch),
                      add filters (eg: verto tag up --pre-release --filter=pre_release_only)
                      or disable tag validation in Vertofile with config.version.validations.new_version_must_be_bigger = false
                    TEXT
                  )
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
      end
    end
  end
end
