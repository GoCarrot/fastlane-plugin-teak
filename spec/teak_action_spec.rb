describe Fastlane::Actions::TeakAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The teak plugin is working!")

      Fastlane::Actions::TeakAction.run(nil)
    end
  end
end
