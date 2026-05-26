import SwiftUI

struct LicenseView: View {
    @StateObject private var licenseViewModel = LicenseViewModel()
    
    var body: some View {
        VStack(spacing: 15) {
            Text("RawSpeech")
                .font(.headline)

            VStack(spacing: 10) {
                Text("Free Edition Active")
                    .foregroundColor(.green)

                Button(role: .destructive, action: {
                    licenseViewModel.removeLicense()
                }) {
                    Text("Clear Stored License Data")
                }
            }
            
            if let message = licenseViewModel.validationMessage {
                Text(message)
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
        .padding()
    }
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
}
