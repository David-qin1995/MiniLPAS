package moe.sekiu.minilpa.web.util

object Validators {
    private val iccidRegex = Regex("^[0-9]{18,22}$")
    private val smdpRegex = Regex("^https?://.+", RegexOption.IGNORE_CASE)

    fun requireValidIccid(iccid: String) {
        if (!iccidRegex.matches(iccid)) throw IllegalArgumentException("ICCID 格式不正确")
    }

    fun requireValidSmdp(url: String) {
        if (!smdpRegex.matches(url)) throw IllegalArgumentException("SMDP 地址必须为 http/https URL")
    }
}


