package util_pkg is
    -- clog2 function
    function clog2 (x : integer) return integer;

    -- clogv function
    function clogv (x : integer; v : integer) return integer;
end util_pkg;

package body util_pkg is
    function clog2 (x : integer) return integer is
        variable i : integer := 0;
    begin
        while 2**i < x loop
            i := i + 1;
        end loop;
        return i;
    end function;

    function clogv (x : integer; v : integer) return integer is
        variable i : integer := 0;
    begin
        while v**i < x loop
            i := i + 1;
        end loop;
        return i;
    end function;
end util_pkg;
