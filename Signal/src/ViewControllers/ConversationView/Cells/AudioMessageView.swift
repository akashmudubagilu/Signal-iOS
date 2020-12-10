//
//  Copyright (c) 2020 Open Whisper Systems. All rights reserved.
//

import Foundation
import Lottie

class AudioMessageView: UIStackView {

    private let audioAttachment: AudioAttachment
    private var attachment: TSAttachment { audioAttachment.attachment }
    private var attachmentStream: TSAttachmentStream? { audioAttachment.attachmentStream }
    private var durationSeconds: TimeInterval { audioAttachment.durationSeconds }

    private let isIncoming: Bool
    private let conversationStyle: ConversationStyle

    private let playPauseAnimation = AnimationView(name: "playPauseButton")
    private let playbackTimeLabel = UILabel()
    private let progressSlider = UISlider()
    private let waveformProgress = AudioWaveformProgressView()

    private var audioPlaybackState: AudioPlaybackState {
        audioPlayer.audioPlaybackState(forAttachmentId: attachment.uniqueId)
    }

    private var elapsedSeconds: TimeInterval {
        guard let attachmentStream = self.attachmentStream else {
            return 0
        }
        return audioPlayer.playbackProgress(forAttachmentStream: attachmentStream)
    }

    @objc
    init(audioAttachment: AudioAttachment, isIncoming: Bool, conversationStyle: ConversationStyle) {
        self.audioAttachment = audioAttachment
        self.isIncoming = isIncoming
        self.conversationStyle = conversationStyle

        super.init(frame: .zero)

        axis = .vertical
        spacing = AudioMessageView.vSpacing

        if !attachment.isVoiceMessage {
            let topText: String
            if let fileName = attachment.sourceFilename?.stripped, !fileName.isEmpty {
                topText = fileName
            } else {
                topText = NSLocalizedString("GENERIC_ATTACHMENT_LABEL", comment: "A label for generic attachments.")
            }

            let topLabel = UILabel()
            topLabel.text = topText
            topLabel.textColor = conversationStyle.bubbleTextColor(isIncoming: isIncoming)
            topLabel.font = AudioMessageView.labelFont
            addArrangedSubview(topLabel)
        }

        // TODO: There is a bug with Lottie where animations lag when there are a lot
        // of other things happening on screen. Since this animation generally plays
        // when the progress bar / waveform is rendering we speed up the playback to
        // address some of the lag issues. Once this is fixed we should update lottie
        // and remove this check. https://github.com/airbnb/lottie-ios/issues/1034
        playPauseAnimation.animationSpeed = 3
        playPauseAnimation.backgroundBehavior = .forceFinish
        playPauseAnimation.contentMode = .scaleAspectFit
        playPauseAnimation.autoSetDimensions(to: CGSize(square: animationSize))
        playPauseAnimation.setContentHuggingHigh()

        let fillColorKeypath = AnimationKeypath(keypath: "**.Fill 1.Color")
        playPauseAnimation.setValueProvider(ColorValueProvider(thumbColor.lottieColorValue), keypath: fillColorKeypath)

        let waveformContainer = UIView.container()
        waveformContainer.autoSetDimension(.height, toSize: AudioMessageView.waveformHeight)

        waveformProgress.playedColor = playedColor
        waveformProgress.unplayedColor = unplayedColor
        waveformProgress.thumbColor = thumbColor
        waveformContainer.addSubview(waveformProgress)
        waveformProgress.autoPinEdgesToSuperviewEdges()

        progressSlider.setThumbImage(UIImage(named: "audio_message_thumb")?.asTintedImage(color: thumbColor), for: .normal)
        progressSlider.setMinimumTrackImage(trackImage(color: playedColor), for: .normal)
        progressSlider.setMaximumTrackImage(trackImage(color: unplayedColor), for: .normal)

        waveformContainer.addSubview(progressSlider)
        progressSlider.autoPinWidthToSuperview()
        progressSlider.autoSetDimension(.height, toSize: 12)
        progressSlider.autoVCenterInSuperview()

        playbackTimeLabel.textColor = conversationStyle.bubbleSecondaryTextColor(isIncoming: isIncoming)
        playbackTimeLabel.font = UIFont.ows_dynamicTypeCaption1.ows_monospaced
        playbackTimeLabel.setContentHuggingHigh()

        let playerStack = UIStackView(arrangedSubviews: [playPauseAnimation, waveformContainer, playbackTimeLabel])
        playerStack.isLayoutMarginsRelativeArrangement = true
        playerStack.layoutMargins = UIEdgeInsets(
            top: AudioMessageView.vMargin,
            leading: hMargin,
            bottom: AudioMessageView.vMargin,
            trailing: hMargin
        )
        playerStack.spacing = hSpacing

        addArrangedSubview(playerStack)

        waveformContainer.autoAlignAxis(.horizontal, toSameAxisOf: playPauseAnimation)

        updateContents(animated: false)

        audioPlayer.addListener(self)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scrubbing

    @objc var isScrubbing = false

    @objc
    func isPointInScrubbableRegion(_ point: CGPoint) -> Bool {
        // If we have a waveform but aren't done sampling it, don't allow scrubbing yet.
        if let waveform = attachmentStream?.audioWaveform(), !waveform.isSamplingComplete {
            return false
        }

        let locationInSlider = convert(point, to: waveformProgress)
        return locationInSlider.x >= 0 && locationInSlider.x <= waveformProgress.width
    }

    @objc
    func progressForLocation(_ point: CGPoint) -> CGFloat {
        let sliderContainer = convert(waveformProgress.frame, from: waveformProgress.superview)
        var newRatio = CGFloatInverseLerp(point.x, sliderContainer.minX, sliderContainer.maxX).clamp01()

        // When in RTL mode, the slider moves in the opposite direction so inverse the ratio.
        if CurrentAppContext().isRTL {
            newRatio = 1 - newRatio
        }

        return newRatio.clamp01()
    }

    @objc
    func scrubToLocation(_ point: CGPoint) -> TimeInterval {
        let newRatio = progressForLocation(point)

        visibleProgressRatio = newRatio

        return TimeInterval(newRatio) * durationSeconds
    }

    // MARK: - Contents

    private static var labelFont: UIFont = .ows_dynamicTypeCaption2
    private static var waveformHeight: CGFloat = 35
    private static var vMargin: CGFloat = 4
    private var animationSize: CGFloat = 28
    private var iconSize: CGFloat = 24
    private var hMargin: CGFloat = 0
    private var hSpacing: CGFloat = 12
    private static var vSpacing: CGFloat = 2

    private lazy var playedColor: UIColor = isIncoming ? .init(rgbHex: 0x92caff) : .ows_white
    private lazy var unplayedColor: UIColor =
        isIncoming ? Theme.secondaryTextAndIconColor.withAlphaComponent(0.3) : UIColor.ows_white.withAlphaComponent(0.6)
    private lazy var thumbColor: UIColor = isIncoming ? Theme.secondaryTextAndIconColor : .ows_white

    // If set, the playback should reflect
    // this progress, not the actual progress.
    // During pan gestures, this gives a preview
    // of playback scrubbing.
    private var overrideProgress: CGFloat?

    @objc
    static var bubbleHeight: CGFloat {
        return labelFont.lineHeight + waveformHeight + vSpacing + (vMargin * 2)
    }

    func updateContents(animated: Bool) {
        updatePlaybackState(animated: animated)
        updateAudioProgress()
//        showDownloadProgressIfNecessary()
    }

    private var audioProgressRatio: CGFloat {
        if let overrideProgress = self.overrideProgress {
            return overrideProgress.clamp01()
        }
        guard durationSeconds > 0 else { return 0 }
        return CGFloat(elapsedSeconds / durationSeconds)
    }

    private var visibleProgressRatio: CGFloat {
        get {
            waveformProgress.value
        }
        set {
            waveformProgress.value = newValue
            progressSlider.value = Float(newValue)
            updateElapsedTime(durationSeconds * TimeInterval(newValue))
        }
    }

    private func updatePlaybackState(animated: Bool = true) {
        let isPlaying = audioPlaybackState == .playing
        let destination: AnimationProgressTime = isPlaying ? 1 : 0

        if animated {
            playPauseAnimation.play(toProgress: destination)
        } else {
            playPauseAnimation.currentProgress = destination
        }
    }

    private func updateElapsedTime(_ elapsedSeconds: TimeInterval) {
        let timeRemaining = Int(durationSeconds - elapsedSeconds)
        playbackTimeLabel.text = OWSFormat.formatDurationSeconds(timeRemaining)
    }

    private func updateAudioProgress() {
        guard !isScrubbing else { return }

        visibleProgressRatio = audioProgressRatio

        if let waveform = attachmentStream?.audioWaveform() {
            waveformProgress.audioWaveform = waveform
            waveformProgress.isHidden = false
            progressSlider.isHidden = true
        } else {
            waveformProgress.isHidden = true
            progressSlider.isHidden = false
        }
    }

    public func setOverrideProgress(_ value: CGFloat, animated: Bool) {
        overrideProgress = value
        updateContents(animated: animated)
    }

    public func clearOverrideProgress(animated: Bool) {
        overrideProgress = nil
        updateContents(animated: animated)
    }

//    private func showDownloadProgressIfNecessary() {
//        guard let attachmentPointer = attachment as? TSAttachmentPointer else { return }
//
//        // We don't need to handle the "tap to retry" state here,
//        // only download progress.
//        guard .failed != attachmentPointer.state else { return }
//
//        // TODO: Show "restoring" indicator and possibly progress.
//        guard .restoring != attachmentPointer.pointerType else { return }
//
//        guard attachmentPointer.uniqueId.count > 1 else {
//            return owsFailDebug("missing unique id")
//        }
//
//        // Add the download view to the play pause animation. This view
//        // will get recreated once the download completes so we don't
//        // have to worry about resetting anything.
//        let downloadView = MediaDownloadView(attachmentId: attachmentPointer.uniqueId, radius: iconSize * 0.5)
//        playPauseAnimation.animation = nil
//        playPauseAnimation.addSubview(downloadView)
//        downloadView.autoSetDimensions(to: CGSize(square: iconSize))
//        downloadView.autoCenterInSuperview()
//    }

    private func trackImage(color: UIColor) -> UIImage? {
        return UIImage(named: "audio_message_track")?
            .asTintedImage(color: color)?
            .resizableImage(withCapInsets: UIEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2))
    }
}

// MARK: -

extension AudioMessageView: CVAudioPlayerListener {
    func audioPlayerStateDidChange() {
        AssertIsOnMainThread()

        updateContents(animated: true)
    }
}
