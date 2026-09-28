//
//  RatingModel.swift
//  FidraData
//
//  Created by hi on 22/8/25.
//

import Foundation

public struct ScriptModel: Codable {
    public let id: String
    public let dialogId: String
    public let title: String
    public let dialogRatePosition: [String]
    public let displayRateIcon: Bool
    public let displayFromSession: Int
    public let displaySessionGap: Int
    public let redisplayCountPerSession: Int
    public let timeGap: Int
    public let dialog: Dialog

    enum CodingKeys: String, CodingKey {
        case id
        case dialogId = "dialog_id"
        case title
        case dialogRatePosition = "dialog_rate_position"
        case displayRateIcon = "display_rate_icon"
        case displayFromSession = "display_from_session"
        case displaySessionGap = "display_session_gap"
        case redisplayCountPerSession = "redisplay_count_per_session"
        case timeGap = "time_gap"
        case dialog
    }
}

public struct Dialog: Codable {
    public let templateId: String
    public let name: String
    public let allowFeedbackAndPhoto: Bool
    public let openFeedbackUnderXStar: Int
    public let contents: [String: Contents]?
    public let appProblems: [AppProblem]
    public let defaultStarRating: Int

    enum CodingKeys: String, CodingKey {
        case templateId = "template_id"
        case name
        case allowFeedbackAndPhoto = "allow_feedback_and_photo"
        case openFeedbackUnderXStar = "open_feedback_under_x_star"
        case contents
        case appProblems = "app_problems"
        case defaultStarRating = "default_star_rating"
    }
}

public struct Contents: Codable {
    public let languageCode: String
    public let title: String
    public let description: String
    public let cta: String
    public let ctaSecondary: String
    public let starRating: String

    enum CodingKeys: String, CodingKey {
        case languageCode = "language_code"
        case title
        case description
        case cta
        case ctaSecondary = "cta_secondary"
        case starRating = "star_rating"
    }
}

public struct AppProblem: Codable {
    public let id: String
    public let translation: String
    public let sendText: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case translation
        case sendText = "send_text"
    }
}

public struct DeviceRegistrationInfo: Codable {
    public let deviceId: String
    public let bundleId: String
    public let version: String
    public let userId: String?
    public let languageCode: String
    public let countryCode: String
    public let deviceType: String
    public let os: String
    public let token: String?
    public let osVersion: String
}

extension ScriptModel {
    public static var defaultModel: ScriptModel {
        ScriptModel(
            id: "",
            dialogId: "",
            title: "Default Rating Dialog",
            dialogRatePosition: ["iap", "result"],
            displayRateIcon: true,
            displayFromSession: 0,
            displaySessionGap: 1,
            redisplayCountPerSession: 1,
            timeGap: 30,
            dialog: Dialog(
                templateId: "template_3",
                name: "Default Dialog",
                allowFeedbackAndPhoto: true,
                openFeedbackUnderXStar: 4,
                contents: [
                    "0": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description: "How do you feel about the app? Your feedback is important to us",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "1": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description:
                            "Oh, no!\nPlease leave us some feedback!",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "2": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description:
                            "Oh, no!\nPlease leave us some feedback!",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "3": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description:
                            "Oh, no!\nPlease leave us some feedback!",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "4": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description:
                            "We like you too!\nThanks for your feedback!",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "5": Contents(
                        languageCode: "en",
                        title: "Rate Us",
                        description:
                            "We like you too!\nThanks for your feedback!",
                        cta: "OK",
                        ctaSecondary: "",
                        starRating: ""
                    ),
                    "love_it": Contents(
                        languageCode: "en",
                        title: "How are we doing?",
                        description: "Whether you love us or feel we could be doing better, we want to know!",
                        cta: "Love it!",
                        ctaSecondary: "Not great 😐",
                        starRating: "How would you rate our app?"
                    )
                ],
                appProblems: [
                    AppProblem(
                        id: "01JPW42EV432YNFKQH0Z29ZSTH",
                        translation: "Many bugs in app",
                        sendText: false
                    ),
                    AppProblem(
                        id: "01JQ8N4B0JRMB92C12M0ZGM438",
                        translation: "Unfriendly user interface",
                        sendText: false
                    ),
                      AppProblem(
                        id: "01JPW42J07E0Y5CY3J5ETM7RXV",
                        translation: "Too many ads",
                        sendText: false
                    ),
                    AppProblem(
                        id: "01JRWB3X0KVK1E5D84HRGK70S8",
                        translation: "Other",
                        sendText: true
                    )
                ],
                defaultStarRating: 5
            )
        )
    }
}

