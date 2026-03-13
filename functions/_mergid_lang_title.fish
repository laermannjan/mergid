function _mergid_lang_title --description "Get human-readable name for language code"
    switch $argv[1]
        case en
            echo English
        case de
            echo Deutsch
        case fr
            echo Français
        case es
            echo Español
        case it
            echo Italiano
        case pt
            echo Português
        case ja
            echo 日本語
        case zh
            echo 中文
        case ko
            echo 한국어
        case ru
            echo Русский
        case nl
            echo Nederlands
        case pl
            echo Polski
        case '*'
            echo $argv[1]
    end
end
