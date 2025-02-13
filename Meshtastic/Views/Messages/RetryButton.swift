import SwiftUI

struct RetryButton: View {
	@Environment(\.managedObjectContext) var context
	@EnvironmentObject var bleManager: BLEManager

	let message: MessageEntity
	@State var isShowingConfirmation = false

	var body: some View {
		Button {
			isShowingConfirmation = true
		} label: {
			Image(systemName: "exclamationmark.circle")
				.foregroundColor(.gray)
				.frame(height: 30)
				.padding(.top, 5)
		}
		.confirmationDialog(
			"This message was likely not delivered.",
			isPresented: $isShowingConfirmation,
			titleVisibility: .visible
		) {
			Button("Try Again") {
				guard bleManager.connectedPeripheral?.peripheral.state == .connected else {
					return
				}
				let messageID = message.messageId
				let payload = message.messagePayload ?? ""
				let userNum = message.toUser?.num ?? 0
				let channel = message.channel
				let isEmoji = message.isEmoji
				let replyID = message.replyID
				context.delete(message)
				do {
					try context.save()
				} catch {
					print("Failed to delete message \(messageID)")
				}
				if !bleManager.sendMessage(
					message: payload,
					toUserNum: userNum,
					channel: channel,
					isEmoji: isEmoji,
					replyID: replyID
				) {
					// Best effort, unlikely since we already checked BLE state
					print("Failed to resend message \(messageID)")
				}
			}
			Button("Cancel", role: .cancel) {}
		}
	}
}
