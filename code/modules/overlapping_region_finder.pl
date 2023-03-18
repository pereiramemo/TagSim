#!/usr/bin/perl

open($IF,$ARGV[0]) or die "no input file privided";

$i=0;
while (<$IF>) {

  # get info
  chomp $_;
  @fields = split("\t", $_);
 
  # create array
  $a[$i][0] = $fields[0];
  $a[$i][1] = $fields[1];
  $a[$i][2] = $fields[2];
  $a[$i][3] = $fields[3];
  $a[$i][4] = $fields[4];
  $a[$i][5] = $_;
  $i = $i + 1;

 #print "$seqid\t$start\t$end\t$dom\t$eval\n";
  
}

$l = $#a;
for ($i = 0; $i <= $l; $i++) {
  for ($j = $i + 1; $j <= $l; $j++) {

    # get cases: same sequence diff dom
    if (($a[$i][0] eq $a[$j][0]) && ($a[$i][4] ne $a[$j][4])) {

      $s1 = $a[$i][1];
      $e1 = $a[$i][2];
      $s2 = $a[$j][1];
      $e2 = $a[$j][2];
      $flag=0;

      # 1st case:
      # seq1       s1--------------e1
      # seq2 s2-------------e2
      if (($s1 > $s2) && ($e1 > $e2) && ($e2 >= $s1) && ($flag == 0))  {
        print "1i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "1j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 2nd case:
      # seq1 s1--------------e1
      # seq2        s2--------------e2
      if (($s1 < $s2) && ($e1 < $e2) && ($s2 <= $e1) && ($flag == 0))  {
        print "2i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "2j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 3rd case:
      # seq1 s1--------------e1
      # seq2 s2--------------e2
      if (($s1 == $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "3i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "3j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 4th case:
      # seq1   s1--------------e1
      # seq2       s2------e2
      if (($s1 < $s2) && ($e1 > $e2) && ($flag == 0))  {
        print "4i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "4j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 5th case:
      # seq1     s1------e1
      # seq2 s2---------------e2
      if (($s1 > $s2) && ($e1 < $e2) && ($flag == 0))  {
        print "5i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "5j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 6th case:
      # seq1 s1------e1
      # seq2 s2---------------e2
      if (($s1 == $s2) && ($e1 < $e2) && ($flag == 0))  {
        print "6i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "6j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 7th case:
      # seq1 s1---------------e1
      # seq2 s2------e2
      if (($s1 == $s2) && ($e1 > $e2) && ($flag == 0))  {
        print "7i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "7j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 8th case:
      # seq1          s1------e1
      # seq2 s2---------------e2
      if (($s1 > $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "8i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "8j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }

      # 9th case:
      # seq1 s1---------------e1
      # seq2           s2-----e2
      if (($s1 < $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "9i\t",$i,"-",$j,"\t",$a[$i][5],"\n";
        print "9j\t",$i,"-",$j,"\t",$a[$j][5],"\n";
        $flag=1;
      }
    }
  }
}
