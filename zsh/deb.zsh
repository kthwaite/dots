function pkg-where {
    # i can never remember what this flag is
    dpkg-query -L $@
}
