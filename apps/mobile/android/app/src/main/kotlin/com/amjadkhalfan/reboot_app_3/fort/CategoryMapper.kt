package com.amjadkhalfan.reboot_app_3.fort

/**
 * Maps Android package names to usage categories.
 * Used by the Fort feature to aggregate app usage at the category level.
 */
object CategoryMapper {

    enum class Category(val key: String) {
        SOCIAL_MEDIA("socialMedia"),
        ENTERTAINMENT("entertainment"),
        GAMES("games"),
        PRODUCTIVITY("productivity"),
        COMMUNICATION("communication"),
        EDUCATION("education"),
        HEALTH("health"),
        NEWS("news"),
        OTHER("other");
    }

    private val socialMediaKeywords = listOf(
        "instagram", "facebook", "twitter", "tiktok", "snapchat",
        "reddit", "linkedin", "pinterest", "tumblr", "threads",
        "zhiliaoapp.musically", "com.x.android"
    )

    private val entertainmentKeywords = listOf(
        "youtube", "netflix", "spotify", "twitch", "hulu",
        "disney", "hbo", "vimeo", "deezer", "anghami",
        "video", "music", "media.player", "shahid", "starzplay"
    )

    private val gamesKeywords = listOf(
        "game", "games", "gaming", "supercell", "rovio",
        "king.com", "gameloft", "ea.game", "com.kiloo", "pubg", "roblox"
    )

    private val communicationKeywords = listOf(
        "whatsapp", "telegram", "signal", "messenger", "viber",
        "wechat", "line.", "kakaotalk", "discord", "slack",
        "com.google.android.apps.messaging", ".sms", ".dialer", ".phone"
    )

    private val productivityKeywords = listOf(
        "docs", "sheets", "slides", "drive", "notion", "todoist",
        "trello", "asana", "evernote", "onenote", "office",
        "calendar", "calculator", "clock", "files", "notion"
    )

    private val educationKeywords = listOf(
        "duolingo", "coursera", "udemy", "khan", "quizlet",
        "learn", "education", "school", "university"
    )

    private val healthKeywords = listOf(
        "health", "fitness", "workout", "meditation", "calm",
        "headspace", "strava", "fitbit", "myfitnesspal"
    )

    private val newsKeywords = listOf(
        "news", "bbc", "cnn", "aljazeera", "reuters",
        "guardian", "nytimes", "flipboard"
    )

    fun categorize(packageName: String): Category {
        val pkg = packageName.lowercase()

        if (matchesAny(pkg, socialMediaKeywords)) return Category.SOCIAL_MEDIA
        if (matchesAny(pkg, entertainmentKeywords)) return Category.ENTERTAINMENT
        if (matchesAny(pkg, gamesKeywords)) return Category.GAMES
        if (matchesAny(pkg, communicationKeywords)) return Category.COMMUNICATION
        if (matchesAny(pkg, productivityKeywords)) return Category.PRODUCTIVITY
        if (matchesAny(pkg, educationKeywords)) return Category.EDUCATION
        if (matchesAny(pkg, healthKeywords)) return Category.HEALTH
        if (matchesAny(pkg, newsKeywords)) return Category.NEWS

        return Category.OTHER
    }

    private fun matchesAny(pkg: String, keywords: List<String>): Boolean {
        return keywords.any { pkg.contains(it) }
    }
}
