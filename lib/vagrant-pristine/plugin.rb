require_relative 'version'
require 'vagrant'
require Vagrant.source_root.join('plugins/commands/up/start_mixins')
require Vagrant.source_root.join('plugins/commands/box/command/download_mixins')

module VagrantPlugins
  module Pristine
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-pristine'

      command("pristine") do
        Command
      end
    end

    class Command < Vagrant.plugin(2, :command)
      include VagrantPlugins::CommandUp::StartMixins
      include VagrantPlugins::CommandBox::DownloadMixins

      def execute
        options = {
          force:    false,
          parallel: true,
          update:   true
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant pristine [vm-name]"
          o.separator ""

          build_start_options(o, options)

          o.on("-f", "--force", "Destroy without confirmation.") do |f|
            options[:force] = f
          end

          o.on("--[no-]parallel",
               "Enable or disable parallelism if provider supports it.") do |parallel|
            options[:parallel] = parallel
          end

          o.on("--provider provider", String,
               "Back the machine with a specific provider.") do |provider|
            options[:provider] = provider
          end

          o.on("--[no-]update", "Enable or disable box update.") do |update|
            options[:update] = update
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return 1 if !argv

        @logger.debug("'Destroy' each target VM...")
        declined = false
        with_target_vms(argv, :reverse => true) do |vm|
          action_env = vm.action(
            :destroy, :force_confirm_destroy => options[:force])

            declined = true if action_env.has_key?(:force_confirm_destroy_result) &&
              action_env[:force_confirm_destroy_result] == false
        end

        # Success if no confirms were declined
        return 1 if declined

          # Build up the batch job of what we'll do
          @env.batch(options[:parallel]) do |batch|
            with_target_vms(argv, :provider => options[:provider]) do |machine|
              if options[:update]
                begin
                  box = machine.box
                  if box
                    @env.ui.output(I18n.t("vagrant.box_update_checking", name: machine.name))

                    update = box.has_update?
                    if !update
                      @env.ui.success(I18n.t(
                        "vagrant.box_up_to_date_single",
                        name: box.name, version: box.version))
                    else
                      @env.ui.output(I18n.t(
                        "vagrant.box_updating",
                        name: update[0].name,
                        provider: update[2].name,
                        old: box.version,
                        new: update[1].version))
                      @env.action_runner.run(Vagrant::Action.action_box_add, {
                        box_url: box.metadata_url,
                        box_provider: update[2].name,
                        box_version: update[1].version,
                        ui: @env.ui
                      })

                      machine.box = @env.boxes.find(update[0].name, update[2].name, update[1].version)
                    end
                  end
                rescue Exception => e
                  # exception will be logged to ui but not thrown, box update failure is not fatal
                  @env.ui.warn e
                end
              else
                @env.ui.output(I18n.t("vagrant.box_update_checking", name: machine.name)+" skipped")
              end

              # turn off default update check
              machine.config.instance_variable_get(:@keys)[:vm].instance_variable_set(:@box_check_update, false)

              FileUtils.mkdir_p machine.data_dir.to_s

              @env.ui.info(I18n.t(
                "vagrant.commands.up.upping",
                :name => machine.name,
                :provider => machine.provider_name))

              batch.action(machine, :up, options)
          end
        end

        return 0
      end
    end
  end
end
