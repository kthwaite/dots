return {
	{
		"goolord/alpha-nvim",
		config = function()
			local alpha = require("alpha")
			local startify = require("alpha.themes.startify")
			local version_string = require("core.utility").version_string
			local section = startify.section
			-- Set header
			local header = {
				type = "text",
				val = {
					"          .;CCC CCCC`<CCC>' ,<CCCCCC>>''.;C>>'''`<CCCCCC><CCC;<C>',<CCC",
					"        . <CCCC, <CC>;,.,;<CCCC>>''.;<>,,,. -CCCC;.``''.;<C>>''',<CCC>",
					"       <C;,CCCCC>.`C>'''''''  --<>;.``''<<<C;.`<<<CCCCCC>,;;<CCCCCCCC>;,",
					"     ,CCCCCCCCC>' . `<C>' .,,zc,`<CCCC, -;.``<<>;<CCCCCCCCCC>>''''''<>'",
					"    .<CCCCC''' zc$$$ccccc$$$$$$$h,.`<<C> <CCC;,,.``<`'CC>' .;<CCCCCC-",
					"     ,CCCC' ,c$$$$$$$$$$$$$$$$$$$$$$cc,.  `'<<CCCCCCCCC,,<C`<CCC>>'    .,.",
					"    ;CCCC' J$$$$$$$$$$$$$$$$$$$$$$$$$$$$$. `<>;,.```<<<<<CCC CC,.,,,;CC>'",
					" .;C><C> z$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$. .`'<<<>>;,, <CC CCCCCCCCCC,,.",
					"<C' `>   $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$c CC>>;;, <C> CC,`CC>>'`'CCCCC",
					"' ;C>;> J$$$$$$$$$$$$$$$$$$$$$$$$$????????$$$.`C''''<><>', CC,.,;;C>'`<CCC",
					"  <CCC  $$$$$$$$$$$$$$$$$$$$$P\"  .,ccccccc$$$$. ,CCC>;,;<C,.``'''  ,<> .,'",
					" ,CCC .<$$$$$$$$$$$$$$$$$$$$\"  zJ$$$$$$$$$$$$$$c <CCCC`<CCCCCCCCC>,`CC'<'",
					",CCC ; J$$$$$$$$$$$$$$$$$$$$,c$$??C????\"\"???$$$$hc`'>' ;.``<CC>>><C C> C>",
					'CC>>;C ?$$$$$???????$$$$$$$$$$$FJP",c==="   J$$$$$c ;, <CC> <C><\\<> C>;CC;',
					'>  >\' . $$P".,,zzcc, "$$$$$$$$$;" ,.    $" J$$$$$$$ <C> CCC <C < > <C `CCC',
					";<CCCC .`$,J$$$PCCC>?<C$$$$$$$$L -??    ,c$$$$$$$$$c C',CC> <' C,,;>   `CC",
					'CCCC>\',C ?$$CCJ?""\'_`,`"$$$$$$$$$c,=cccd$$$$$$$$$$$$ C <C>  ,; C <>     `C',
					'CCCC;,> .`$$$",==""-.  c<$$$$$$$$$$JJJJC?$$$$$$$$$$$ < CC < CC C,`>      `',
					"CCCCCC;<C,`$F' .    `,JC:<$$$$$$$$$$$$$$$$$$$$$$$$$$>` <>-C CC,`C,`,.",
					"`<C>`'CCCC,`h.,..,,,c$3C>:3$$$$$$$$$$$$$$$$$$$$$$$$$$ < <,<><`C;.`, <> .",
					"    <C`<CC> $$$$$$$$$$$CC;<$$$$$$$$$$$$$$$$$$$$$$$$$$r`<;CCCCCCC>.' <> C;,",
					"  ;CCC. CC>-`$$$$$$$$$$$CC:$$$$$$$$$?$$$$$$$$$$$$$$$$$.`<'`<CCCC>',C' <CCC",
					"  <CC',<>',;.?$$$$$$$$$$C>;$$$$$9???-<$$$$$$$$$$$$$$$$$c,`-.``---''.,CCC>>",
					",C'CCCC ;.`C> $$$$$$$$$$$>`$$$$$F<;,c$$$$$$$$$$$$$$$$$$$$L `C>>;;<CCCCCCCC",
					"C> CC>C,`C,`> `?$$$$$$$$$h;` `\"'.<$$$$$$$$$$$$$$$$$$$$$$$P . CCCCC,.;;.`''",
					"'  `C `C;CC,CC; \"$$$$$$$$$$$$$$$$<$$$$$$$$$$$$$$$$$$$$$$P' C,`CCCCCCCCCCCC",
					'    `C,.``<CCCCC, ?$$$$$$$$$$$????""\'"""" J$$$$$$$$$$$$" ..`C,C>`<<<<>>\'\'<',
					"     `CCCC;.``<CC>.`$$$$$$$???     .,c=:c$$$$$$$$$$$$P',$'< CC'C;  <CCCC>;",
					'       <CCCCC>, `CC, "$$$$$hcc,"?C????JJ$$$$$$$$$$$$",J$$ C CC <C . ``\'\',.',
					"          `C>`CC,`<CC, \"$$$$$$$$$$>;;??$$$$$$$$$$$P',$$$$ C CC> C,`C;. <CC",
					'         .,CC,`<C,,CCC .`?$$$$$$$$JJ$$$$$$$$$$$$P",J$$$$F.>,CC><CC CCC> <C',
					"       ;C>'CCC>.`<'<CC $c, ?$$$$$$$$$$$$$$$$$$$\" c$$$$$$ <><C> <CC ``<C;.`",
					"      ,CC> `CCCCCCCCC',$$$h.`?$$$$$$$$$$$$$$$\" z$$$$$$$F;CC>',<CC>,C>.`<C;",
					"      <C> <>.`'''<>'  $$$$$$$c \"$$$$$$$$$??\".z$$$$$$$$$ `\".;<CCC> .`<C; CC",
					"      CC <CCC <C'<Cr J$$$$$$$$$c,``''\"\"'.zc$$$$$$$$$$$F;;CCCCC>' ;C, <CCCC",
					"     <CC C><C CC CCC $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ CCCC>' .c;`<C> C <C",
					" ",
				},
				opts = {
					position = "center",
				},
			}
			section.mru.opts = { position = "center" }
			startify.opts.layout = {
				{ type = "padding", val = 1 },
				header,
				{ type = "text", val = "NVIM" .. version_string(), opts = { position = "center" } },
				{ type = "padding", val = 1 },
				section.top_buttons,
				{ type = "group", val = { section.mru }, opts = { position = "center" } },
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
