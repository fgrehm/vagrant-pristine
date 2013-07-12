require_relative 'version'

module VagrantPlugins
  module Pristine
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-pristine'

      command("pristine") do
        Command
      end
    end

    class Command < Vagrant.plugin(2, :command)
      def execute
        options = {
          force:    false,
          parallel: true
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant pristine [vm-name]"
          o.separator ""

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
