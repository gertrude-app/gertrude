import Foundation

enum LocalizedStringKey: String {
  case addShowAddByUrl = "addShow.addByUrl"
  case addShowAllowImages = "addShow.allowImages"
  case addShowAlreadySubscribed = "addShow.alreadySubscribed"
  case addShowEnterUrl = "addShow.enterUrl"
  case addShowError = "addShow.error"
  case addShowHowToAdd = "addShow.howToAdd"
  case addShowNoImages = "addShow.noImages"
  case addShowSearch = "addShow.search"
  case addShowShowArtworkQuestion = "addShow.showArtworkQuestion"
  case addShowSubscribe = "addShow.subscribe"
  case addShowSubscribing = "addShow.subscribing"
  case episodeDownloadFailed = "episode.downloadFailed"
  case episodeDownloadNoInternet = "episode.downloadNoInternet"
  case onboardingAllSet = "onboarding.allSet"
  case onboardingAreYouParent = "onboarding.areYouParent"
  case onboardingContinue = "onboarding.continue"
  case onboardingExplainPin = "onboarding.explainPin"
  case onboardingGotItNext = "onboarding.gotItNext"
  case onboardingNoChild = "onboarding.noChild"
  case onboardingOkLetsGo = "onboarding.okLetsGo"
  case onboardingParentRequired = "onboarding.parentRequired"
  case onboardingStrongPin = "onboarding.strongPin"
  case onboardingYesParent = "onboarding.yesParent"
  case pinCancel = "pin.cancel"
  case pinChangeSuccess = "pin.changeSuccess"
  case pinChangeProceed = "pin.changeProceed"
  case pinChangeInstructions = "pin.changeInstructions"
  case podcastsDeleteConfirm = "podcasts.deleteConfirm"
  case podcastsDeleteWarning = "podcasts.deleteWarning"
  case podcastsRequestReviewGiveRating = "podcasts.requestReview.giveRating"
  case podcastsRequestReviewLeaveReview = "podcasts.requestReview.leaveReview"
  case podcastsRequestReviewMessage = "podcasts.requestReview.message"
  case podcastsRequestReviewNoThanks = "podcasts.requestReview.noThanks"
  case showsDelete = "shows.delete"
}

func lstr(_ key: LocalizedStringKey) -> String {
  String(localized: String.LocalizationValue(key.rawValue), bundle: .module)
}
