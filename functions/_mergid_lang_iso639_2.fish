function _mergid_lang_iso639_2 --description "Convert ISO 639-1 code to ISO 639-2/T (3-letter) code"
    switch $argv[1]
        case en
            echo eng
        case de
            echo deu
        case fr
            echo fra
        case es
            echo spa
        case it
            echo ita
        case pt
            echo por
        case ja
            echo jpn
        case zh
            echo zho
        case ko
            echo kor
        case ru
            echo rus
        case nl
            echo nld
        case pl
            echo pol
        case '*'
            echo $argv[1]
    end
end
