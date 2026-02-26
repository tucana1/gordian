import ManagedSettingsUI

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: .systemBackground,
            icon: .init(systemName: "lock.shield.fill"),
            title: ShieldConfiguration.Label(
                text: "App Restricted",
                color: .label
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is blocked by Gordian. Open Gordian and scan your key to unlock.",
                color: .secondaryLabel
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Gordian",
                color: .white
            ),
            primaryButtonBackgroundColor: .systemBlue,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: "OK",
                color: .systemBlue
            )
        )
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configuration(shielding: application)
    }
}
