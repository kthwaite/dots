local header_text = {
    [[DPbbbbbbPPPDDxxbbDbbbDDPDbbDDDDDDbDP41K>wzC1544ZZPPPDDbbbPDbbbbDDb4wDPDb4z13C5)5]],
    [[DDbDDbDbPPDDPxbDbPPbbPbbPbDbP1(w11Fz)C151515z)5RwKRwww1PPxxxbPbbDPEwEbz1CzC1wCw)]],
    [[bbbbbDDPPPbDbPbDbbbPbPbPPb)zz)CCFzCF15C1F115151Cw5C1wwwu1zCCzCFCC)C5Cc5C1Cw)C5zF]],
    [[DbPbDDPPxDbDDbDbPbbbPPPR1czcCzuF.,Cz5C)z)11)1c51w155Cc1w51)1zFF1z1z))1cC1)CCw)w1]],
    [[DDbDbDDDbPDbPbbbxbL Fc LC1,)zCFc,c)zzc))w,,1)>1z1zzC 5C)zCzw)CC)zCCzzzCC1>w)w15w]],
    [[bPDbbbPbPPPPbDbu >33uZw3FCc1zc>  c  z)zCzFzLc>Fc ,)),.zz)Z)),>)CzC)FF15CCz)1wC5w]],
    [[bbbbbPxPbbxbPE,L>Lzx)FCC  ,3EzF >z,c ,zL>(.L>cc))C)55,>515CFccc)zCc)zz>1)11C,5ww]],
    [[DDDbDDbbPDbxuLzzCuz))uC13xL15ZE3Eu51Z155u)F)(cLcz,FCc))wCCczC)C51C111zC1)F1C15Cw]],
    [[DbbDDbDbbP((F13EF,Fc(,C(C13ZEZ5u44KRR4R4RF)C)1)(,cczz)C))C))1CC))1))5CFFCzCz))CE]],
    [[bDDbbbbbbbLF(11>> .1ZF(133EEEEPZP4KK4RRRKKKRbb5Z L. cc>zC,> >,,,)zC5CFczzFzzRwww]],
    [[bDPbbDDbP(FFC5CC>CCF)3F15EZ1EuEEEbKbRKKRbbDKDRbKb4F,>c,.c,zzzz,>czc>Cc>z>zw1111C]],
    [[DDbbbPx3F3zC()F>cCF33311ZCEEuZEZ44ERKKRKKKRRRRRRKRRZ,>c(,>c  .,),,)c5>) z5wC5115]],
    [[bxbPE3uF1>,L.c,L3FCuFF3Fu53uZ3E4E44RR44bKRRRDRRDRbR4b>cc>,zC)z1c)1>C5cz)CCzz1zCC]],
    [[PPbcZ5u )(3 > ,uuuZFZuZ5uZCE1EwZ4EEwKw4KRRbKKKDbDRKbRb,,c.z,z>zz)ccczz))>zcczcC,]],
    [[bDb11Lcb >LCCc ZuC1ZEZ115EZuuZEEEwb4EEEwZ, 3xRPRRPRDbbbE,z>zc(.z), >C)zc( F).)1z]],
    [[bbbCZ4ccL)F) (P>33u)EuZCuCu3E4EwE3EEFzLZEE4bbb4bbKbDRRb4cRc czczCCCCC,z) Cc1 >F5]],
    [[bPDbFc,FCzF C(5uucFFEC)Z)C3ZZZEEZ3b4Z4E4E4u>1EEZ4EEbKK4b44 z,cF>))cz)C)Cw5C1wzz1]],
    [[PxbPDcL(cF,>z..ZZLFCu5F(ZFZ1EZZuuZE44b4EZZ(L EE44bcLZEbbbEZzL,  z>)c C555511CcCz]],
    [[bPP 3LL,,c (., ZZFcc,3),3>(>3Zu5EZ4PRbZE3  L., (3b4(44bRRR4RLc Z )z1 CC,C),C.C,)]],
    [[bPx(c1(C(1cx(,,,F33FF3FF3>)(FLuzEE44bEE43, .>,cb(EEbbDbKKbEEwc >,>C)>)CC))111115]],
    [[bD> zw )z1F5cc>,33F3FcL(cL,(.F((z544bRbbb4Z33PEPPEbRRRKRbKRE1L,, zCzCC5>C)1)5www]],
    [[bb3F>zzc)uuL(cL.,uFF(L3L   >(c.cL1EKKRDRKRDbDDZKbbDbRDKDKRKR,)LLz>zzz15>zCz11www]],
    [[PPPZZ,c zc)F(3LF, 3C, L c3cccu33334ERRRRRRKbRbDRRERKbbRRRRRRb)>..c)5zC5z,CC1)5Rw]],
    [[bDbDbPDFz>)cc(3(5zL)FF>.>)((LZZ cFEZbRKKKRRbb44bbb4bKbbbbbKbKZ(.cz>c1zz1C))zc)ww]],
    [[DbbDbbbbz>,z((>1F13Zu)u3>CuZuF(FuFcE44bK44KbEbbE4KxKbbbKbR4b45cL,c)Cz>zC15>)>)C1]],
    [[bbPbbbPbP LLZ1cFc3>,)ZC>uCC)EzFEcLZCZE4E4Kb4EEbK4E4Kbb4bRKEKKbZ>(.> ,C>1)z1CC1C1]],
    [[bbbPbPbPx.>uL(33 c,,,ZuzF3CZCCZ((3(FZK544EF3E3bE444bK4bb4bb4EE5EFz,(cz ).,CccC15]],
    [[bDDDbbE)4L>)c)x3cc. c  )FF)z3ZCZ>L(c,uFE bEbR4R4bKK4bbbKK44b4w4EEEZ,L z,)CzC )>Z]],
    [[PbPPP 3PZ4(zCCu1FL (L,>3uFuuFFC3(cc,>,> LEERRbRRRREbDKRbbKb444EEZuu>, .L),,Lc.cc]],
    [[bbDbD3RxDu3cE3>Z.3(c(L>LuuC3F53Cu(333333ZEbRbRRbEE4K4RKKbK4b4EEEZEL>.L Lc>z>)zC)]],
    [[DDDDDDDRKDRZzCFLF))FuFu,c,uc3u3ZZuu3uEuFE3ZEu3uc,.(4EEDKRbbKKbb44LF, >,c  .)cz>z]],
    [[DDDDDDPDbPPP(Fczz(LFF((11C>uF3C)uFuu(.(,>,.c33Eu4bbbRbRRRb44EEZZ3F3c 3c FCc,.c,>]],
    [[DDDDDDDbDR4xPEFz(>3LFcccF>F1LuuCC)uZLE3Lu33)3ZE44RbRbRRKbb4ZbE3uzCu.,c>FZ5FuL,cz]],
    [[DDDbDDDRDDbbbbPP>1Fc(,z))uFFz,uE)uE)EFuCE33Z)CEbbDKKRRRRRKKbEFZ)Z( c, uFC5(Pxx3>]],
    [[DDDDDDDbDDbbPPbwC.(3F>(LFu>1cc(,>3uzCC553Z3EEK44bKRRRK4RK4KZ4bEZEE>(x))c55(DxPPD]],
    [[DDRDDDDDDDbDDRC)3c((FxEu,)LL.>>x,(,(uuEFZEZE44bbbKKDKKb4wK4RRRb4b.Lc(F>C>DDDPPxb]],
    [[DDDDDDbDDDDKDC1C>x (F(z133(Lc,x3((3L(.Z3uZZZE4ZRKbERR4E4bRRKRKK4E,L3EuzRRDRKZK4P]],
    [[DDDDDDDDbDbD3CFz1z1C(C..(c>,(>33x((u(cF(ZZuzEEuECEZEubbbRRbKRRRb (. L3xLbDE15wRw]],
    [[DDDDDDDbDbDbK)F(z)L1(C5c)1,Lcc3zFuuE)c33CE(L .EZEKKKRRbDRKRRDRKbc c((LPP),wwwwww]],
    [[DDDDDDDDRDbDF)F(3)3)zz ( 15c3F3Z3)u1C1ZZ5ZZZEKKbbRRKEbRRRDRKRbbx3,Pb(c))1w,)wwRw]],
}
local header_colours = {
    [[ABCCCCCCBBBAADDCCACCCAABACCAAAAAACABEFGHIJKFLEEMMBBBAACCCBACCCCAACEIABACEJFNKLOL]],
    [[AACAACACBBAABDCACBBCCBCCBCACBFPIFFQJOKFLFLFLJOLRIGRIIIFBBDDDCBCCABSISTJFKJKFIKIO]],
    [[CCCCCAABBBCACBCACCCBCBCBBCOJJOKKQJKQFLKFQFFLFLFKILKFIIIUFJKKJKQKKOKLKVLKFKIOKLJQ]],
    [[ACBCAABBDACAACACBCCCBBBRFVJVKJUQWXKJLKOJOFFOFVLFIFLLKVFILFOFJQQFJFJOOFVKFOKKIOIF]],
    [[AACACAAACBACBCCCDCYZQVZYKFXOJKQVXVOJJVOOIXXFOHFJFJJKZLKOJKJIOKKOJKKJJJKKFHIOIFLI]],
    [[CBACCCBCBBBBCACUZHNNUMINQKVFJVHZZVZZJOJKJQJYVHQVZXOOXWJJOMOOXHOKJKOQQFLKKJOFIKLI]],
    [[CCCCCBDBCCDCBSXYHYJDOQKKZZXNSJQZHJXVZXJYHPWYHVVOOKOLLXHLFLKQVVVOJKVOJJHFOFFKXLII]],
    [[AAACAACCBACDUYJJKUJOOUKFNDYFLMSNSULFMFLLUOQOPVYVJXQKVOOIKKVJKOKLFKFFFJKFOQFKFLKI]],
    [[ACCAACACCBPPQFNSQXQVPXKPKFNMSMLUEEGRRERERQOKOFOPXVVJJOKOOKOOFKKOOFOOLKQQKJKJOOKS]],
    [[CAACCCCCCCYQPFFHHZWFMQPFNNSSSSBMBEGGERRRGGGRTTLMZYWZVVHJKXHZHXXXOJKLKQVJJQJJRIII]],
    [[CABCCAACBPQQKLKKHKKQONQFLSMFSUSSSTGTRGGRTTAGARCGTEQXHVXWVXJJJJXHVJVHKVHJHJIFFFFK]],
    [[AACCCBDNQNJKPOQHVKQNNNFFMKSSUMSMEESRGGRGGGRRRRRRGRRMXHVPXHVZZWXOXXOVLHOZJLIKLFFL]],
    [[CDCBSNUQFHXYWVXYNQKUQQNQULNUMNSESEERREETGRRRARRARTRETHVVHXJKOJFVOFHKLVJOKKJJFJKK]],
    [[BBCVMLUZOPNZHZXUUUMQMUMLUMKSFSIMESSIGIEGRRTGGGATARGTRTXXVWJXJHJJOVVVJJOOHJVVJVKX]],
    [[CACFFYVCZHYKKVZMUKFMSMFFLSMUUMSSSITESSSIMXZNDRBRRBRATTTSXJHJVPWJOXZHKOJVPZQOWOFJ]],
    [[CCCKMEVVYOQOZPBHNNUOSUMKUKUNSESISNSSQJYMSSETTTETTGTARRTEVRVZVJVJKKKKKXJOZKVFZHQL]],
    [[CBACQVXQKJQZKPLUUVQQSKOMOKNMMMSSMNTEMESESEUHFSSMESSTGGETEEZJXVQHOOVJOKOKILKFIJJF]],
    [[BDCBAVYPVQXHJWWMMYQKULQPMQMFSMMUUMSEETESMMPYZSSEETVYMSTTTSMJYXZZJHOVZKLLLLFFKVKJ]],
    [[CBBZNYYXXVZPWXZMMQVVXNOXNHPHNMULSMEBRTMSNZZYWXZPNCEPEETRRRERYVZMZOJFZKKXKOXKWKXO]],
    [[CBDPVFPKPFVDPXXXQNNQQNQQNHOPQYUJSSEETSSENXZWHXVTPSSTTATGGTSSIVZHXHKOHOKKOOFFFFFL]],
    [[CAHZJIZOJFQLVVHXNNQNQVYPVYXPWQPPJLEETRTTCEMNNBSBBSTRRRGRTGRSFYXXZJKJKKLHKOFOLIII]],
    [[CCNQHJJVOUUYPVYWXUQQPYNYZZZHPVWVYFSGGRARGRATAAMGTTATRAGAGRGRXOYYJHJJJFLHJKJFFIII]],
    [[BBBMMXVZJVOQPNYQXZNKXZYZVNVVVUNNNNESRRRRRRGTRTARRSRGTTRRRRRRTOHWWVOLJKLJXKKFOLRI]],
    [[CACACBAQJHOVVPNPLJYOQQHWHOPPYMMZVQSMTRGGGRRTTEETTTETGTTTTTGTGMPWVJHVFJJFKOOJVOII]],
    [[ACCACCCCJHXJPPHFQFNMUOUNHKUMUQPQUQVSEETGEEGTSTTSEGDGTTTGTRETELVYXVOKJHJKFLHOHOKF]],
    [[CCBCCCBCBZYYMFVQVNHXOMKHUKKOSJQSVYMKMSESEGTESSTGESEGTTETRGSGGTMHPWHZXKHFOJFKKFKF]],
    [[CCCBCBCBDWHUYPNNZVXXXMUJQNKMKKMPPNPQMGLEESQNSNTSEEETGETTETTESSLSQJXPVJZOWXKVVKFL]],
    [[CAAACCSOEYHOVODNVVWZVZZOQQOJNMKMHYPVXUQSZTSTRERETGGETTTGGEETEIESSSMXYZJXOKJKZOHM]],
    [[BCBBBZNBMEPJKKUFQYZPYXHNUQUUQQKNPVVXHXHZYSSRRTRRRRSTAGRTTGTEEESSMUUHXZWYOXXYVWVV]],
    [[CCACANRDAUNVSNHMWNPVPYHYUUKNQLNKUPNNNNNNMSTRTRRTSSEGERGGTGETESSSMSYHWYZYVHJHOJKO]],
    [[AAAAAAARGARMJKQYQOOQUQUXVXUVNUNMMUUNUSUQSNMSUNUVXWPESSAGRTTGGTTEEYQXZHXVZZWOVJHJ]],
    [[AAAAAABACBBBPQVJJPYQQPPFFKHUQNKOUQUUPWPXHXWVNNSUETTTRTRRRTEESSMMNQNVZNVZQKVXWVXH]],
    [[AAAAAAATAREDBSQJPHNYQVVVQHQFYUUKKOUMYSNYUNNONMSEERTRTRRGTTEMTSNUJKUWXVHQMLQUYXVJ]],
    [[AAACAAARAACCCCBBHFQVPXJOOUQQJXUSOUSOSQUKSNNMOKSTTAGGRRRRRGGTSQMOMPZVXZUQKLPBDDNH]],
    [[AAAAAAACAACTBBCIKWPNQHPYQUHFVVPXHNUJKKLLNMNSSGEETGRRRGERGEGMETSMSSHPDOOVLLPADBBA]],
    [[AARAAAAAAACAARKONVPPQDSUXOYYWHHDXPXPUUSQMSMSEETTTGGAGGTEIGERRRTETWYVPQHKHAAABBDC]],
    [[AAAAAACAAAAGAKFKHDZPQPJFNNPYVXDNPPNYPWMNUMMMSEMRGTSRRESETRRGRGGESXYNSUJRRARGMGEB]],
    [[AAAAAAAACACANKQJFJFKPKWWPVHXPHNNDPPUPVQPMMUJSSUSKSMSUTTTRRTGRRRTZPWZYNDYCASFLIRI]],
    [[AAAAAAACACACGOQPJOYFPKLVOFXYVVNJQUUSOVNNKSPYZWSMSGGGRRTARGRRARGCVZVPPYBBOXIIIIII]],
    [[AAAAAAAARACAQOQPNONOJJZPZFLVNQNMNOUFKFMMLMMMSGGTTRRGSTRRRARGRTTDNXBCPVOOFIXOIIRI]],
}
local colour_map = {
    ["B"] = { fg = "#97a5b5" },
    ["S"] = { fg = "#b79877" },
    ["V"] = { fg = "#3d2f18" },
    ["Z"] = { fg = "#000000" },
    ["J"] = { fg = "#533c14" },
    ["Y"] = { fg = "#493e32" },
    ["D"] = { fg = "#81868f" },
    ["A"] = { fg = "#ccdbeb" },
    ["C"] = { fg = "#aec1d5" },
    ["H"] = { fg = "#30220e" },
    ["L"] = { fg = "#c29631" },
    ["F"] = { fg = "#a37a20" },
    ["O"] = { fg = "#694d1d" },
    ["T"] = { fg = "#d8c4a9" },
    ["N"] = { fg = "#80674b" },
    ["X"] = { fg = "#201607" },
    ["I"] = { fg = "#ddb547" },
    ["Q"] = { fg = "#745a31" },
    ["K"] = { fg = "#8a6521" },
    ["R"] = { fg = "#ecdebe" },
    ["G"] = { fg = "#e1ceac" },
    ["W"] = { fg = "#0b0601" },
    ["E"] = { fg = "#cdb598" },
    ["P"] = { fg = "#5d4f3d" },
    ["U"] = { fg = "#93734d" },
    ["M"] = { fg = "#a0815d" },
}


local function getLen(str, start_pos)
    local byte = string.byte(str, start_pos)
    if not byte then
        return nil
    end

    return (byte < 0x80 and 1) or (byte < 0xE0 and 2) or (byte < 0xF0 and 3) or (byte < 0xF8 and 4) or 1
end

local function colorize(header, header_color_map, colors)
    for letter, color in pairs(colors) do
        local color_name = "AlphaJemuelKwelKwelWalangTatay" .. letter
        vim.api.nvim_set_hl(0, color_name, color)
        colors[letter] = color_name
    end

    local colorized = {}

    for i, line in ipairs(header_color_map) do
        local colorized_line = {}
        local pos = 0

        for j = 1, #line do
            local start = pos
            pos = pos + getLen(header[i], start + 1)

            local color_name = colors[line:sub(j, j)]
            if color_name then
                table.insert(colorized_line, { color_name, start, pos })
            end
        end

        table.insert(colorized, colorized_line)
    end

    return colorized
end

return {
    {
        "goolord/alpha-nvim",
        config = function()
            local alpha = require("alpha")
            local startify = require("alpha.themes.startify")
            local version_string = require("core.utility").version_string
            local section = startify.section
            -- Set header
            section.mru.opts = { position = "center" }
            startify.opts.layout = {
                { type = "padding", val = 1 },
                {
                    type = "text",
                    val = header_text,
                    opts = { position = "center", hl = colorize(header_text, header_colours, colour_map) },
                },
                { type = "text",    val = "NVIM" .. version_string(), opts = { position = "center" } },
                { type = "padding", val = 1 },
                section.top_buttons,
                { type = "group",   val = { section.mru }, opts = { position = "center" } },
                section.mru_cwd,
                { type = "padding", val = 1 },
                section.bottom_buttons,
                section.footer,
            }
            startify.section.header.opts.hl = "#33ff33"
            alpha.setup(startify.config)
        end,
    },
}
