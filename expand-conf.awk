function expand (s) {
    if ($0 ~ /^includedir/) {
        cmd = sprintf("/bin/find %s -type f\n", $2)
        while (cmd | getline > 0 )
            system(sprintf("/bin/awk -f %s %s\n", script, $0))
    } else
        print
}

BEGIN {
    script = ""
    file = ""

    for (i = 0; i < length(PROCINFO["argv"]); i++) {
        if (PROCINFO["argv"][i] == "-f") {
            script = PROCINFO["argv"][i + 1]

            break
        }
    }

    file = PROCINFO["argv"][i + 2]

    if (length(script) == 0 || length(file) == 0) {
        print "use \"awk -f <script> /etc/krb5.conf\""

        exit 1
    }

    printf("##include %s\n", file)
}

{
    expand($0)
}
