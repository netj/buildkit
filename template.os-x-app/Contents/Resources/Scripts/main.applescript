property processGroups : {}

on run (args)
	open args
end run

on open fs
	startProcess(fs)
end open

on quit
	stopAllProcesses()
	continue quit
end quit

on idle
	if (count me) is 0 then quit
end idle

on count
        try
	    if (count processGroups) > 0 then
	        set processGroups to words of ¬
	            (do shell script "ps -o pgid= -g "& processGroups &" | sort -u")
	    end if
	end try
        return (count processGroups)
end count

to startProcess(fs)
	set startScript to POSIX path of (path to resource "Scripts/start.sh")
	set names to ""
	repeat with f in fs
		set names to names & " " & quoted form of (POSIX path of f)
	end repeat
        set the end of processGroups to runCommand( ¬
		"set -m; "& ¬
		quoted form of startScript & names &" &"& ¬
                "echo $!")
end startProcess

to stopAllProcesses()
	repeat while (count processGroups) > 0
	    set pgids to ""
	    repeat with pgid in processGroups
	        set pgids to pgids &" -"& pgid
	    end repeat
	    try
	        runCommand("kill -TERM "& pgids &" || true")
	        count me
	        if (count processGroups) > 0 then
	            runCommand("kill -KILL "& pgids &" || true")
	            set processGroups to {}
	        end if
	    end try
	end repeat
end stopAllProcesses

to runCommand(cmd)
	set pathDir to POSIX path of (path to resource "Files/@@APPPATHDIR@@")
	do shell script ¬
		"set -eu; "& ¬
		"export PATH="& quoted form of pathDir &":\"$PATH\"; "& ¬
		cmd
end runCommand
