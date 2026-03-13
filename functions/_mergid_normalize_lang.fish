function _mergid_normalize_lang --description "Normalize language code to ISO 639-1"
    switch (string lower -- $argv[1])
        case en eng english
            echo en
        case de deu ger german deutsch
            echo de
        case fr fra fre french
            echo fr
        case es spa spanish
            echo es
        case it ita italian
            echo it
        case pt por portuguese
            echo pt
        case ja jpn japanese
            echo ja
        case zh zho chi chinese
            echo zh
        case ko kor korean
            echo ko
        case ru rus russian
            echo ru
        case nl nld dut dutch
            echo nl
        case pl pol polish
            echo pl
    end
end
