module seg7 (
  input       [3:0] bcd,
  output reg  [7:0] seg
); 
  //always block for converting bcd digit into 7 segment format
    always @( bcd ) begin
      case (bcd) //case statement
        0  :     seg = 8'b1100_0000; //0     A B C D E F G H  LOW IS ACTIVE
        1  :     seg = 8'b1111_1001; //1
        2  :     seg = 8'b1010_0100; //2       -- H --
        3  :     seg = 8'b1011_0000; //3      |       |
        4  :     seg = 8'b1001_1001; //4      C       G
        5  :     seg = 8'b1001_0010; //5      |       |
        6  :     seg = 8'b1000_0010; //6       -- B --
        7  :     seg = 8'b1111_1000; //7      |       |
        8  :     seg = 8'b1000_0000; //8      D       F
        9  :     seg = 8'b1001_0000; //9      |       |
        10 :     seg = 8'b1000_1000; //A       -- E --   .A
        11 :     seg = 8'b1000_0011; //b
        12 :     seg = 8'b1100_0110; //C
        13 :     seg = 8'b1010_0001; //d
        14 :     seg = 8'b1000_0110; //E
        15 :     seg = 8'b1000_1110; //F
        default: seg = 8'b11111111; 
      endcase
    end
endmodule

module seg7e (
  input       [4:0] bcd,
  output reg  [7:0] seg
); 
    always @( bcd ) begin
      case (bcd) //case statement
        0  :     seg = 8'b1100_0000; //0    A B C D E F G H  LOW IS ACTIVE
        1  :     seg = 8'b1111_1001; //1
        2  :     seg = 8'b1010_0100; //2       -- H --
        3  :     seg = 8'b1011_0000; //3      |       |
        4  :     seg = 8'b1001_1001; //4      C       G
        5  :     seg = 8'b1001_0010; //5      |       |
        6  :     seg = 8'b1000_0010; //6       -- B --
        7  :     seg = 8'b1111_1000; //7      |       |
        8  :     seg = 8'b1000_0000; //8      D       F
        9  :     seg = 8'b1001_0000; //9      |       |
        10 :     seg = 8'b1000_1000; //A       -- E --   .A
        11 :     seg = 8'b1000_0011; //b
        12 :     seg = 8'b1100_0110; //C
        13 :     seg = 8'b1010_0001; //d
        14 :     seg = 8'b1000_0110; //E
        15 :     seg = 8'b1000_1110; //F
        16 :     seg = 8'b1000_1001; //H
        17 :     seg = 8'b1100_0111; //L
        18 :     seg = 8'b0111_1111; //.
        19 :     seg = 8'b0111_1101; //!
        20 :     seg = 8'b1101_0101; //:)
        default: seg = 8'b11111111; 
      endcase
    end
endmodule