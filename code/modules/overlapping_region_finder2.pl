#!/usr/bin/perl

open($IF,$ARGV[0]) or die "no input file privided";

$i=0;
while (<$IF>) {

  # get info
  chomp $_;
  @fields = split("\t", $_);
 
  # create array
  $a[$i]{id} = $fields[0];
  $a[$i]{ali_start_nuc} = $fields[1];
  $a[$i]{ali_end_nuc} = $fields[2];
  $a[$i]{i_evalue} = $fields[3];
  $a[$i]{score} = $fields[4];
  $a[$i]{hmm} = $fields[5];
  $a[$i]{line} = $_;
  $i = $i + 1;

 #print "$seqid\t$start\t$end\t$dom\t$eval\n";
  
}

$l = $#a;
for ($i = 0; $i <= $l; $i++) {
  for ($j = $i + 1; $j <= $l; $j++) {

    # get cases: same sequence diff dom
    $id1=$a[$i]{id};
    $id2=$a[$j]{id};
    $hmm1=$a[$i]{hmm};
    $hmm2=$a[$j]{hmm};
    
    if (($id1 eq $id2) && ($hmm1 ne $hmm2)) {

      $s1 = $a[$i]{ali_start_nuc};
      $e1 = $a[$i]{ali_end_nuc};
      $s2 = $a[$j]{ali_start_nuc};
      $e2 = $a[$j]{ali_end_nuc};
      $flag=0;

      # 1st case:
      # seq1       s1--------------e1
      # seq2 s2-------------e2
      if (($s1 > $s2) && ($e1 > $e2) && ($e2 >= $s1) && ($flag == 0))  {
        print "1i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "1j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 2nd case:
      # seq1 s1--------------e1
      # seq2        s2--------------e2
      if (($s1 < $s2) && ($e1 < $e2) && ($s2 <= $e1) && ($flag == 0))  {
        print "2i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "2j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 3rd case:
      # seq1 s1--------------e1
      # seq2 s2--------------e2
      if (($s1 == $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "3i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "3j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 4th case:
      # seq1   s1--------------e1
      # seq2       s2------e2
      if (($s1 < $s2) && ($e1 > $e2) && ($flag == 0))  {
        print "4i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "4j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 5th case:
      # seq1     s1------e1
      # seq2 s2---------------e2
      if (($s1 > $s2) && ($e1 < $e2) && ($flag == 0))  {
        print "5i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "5j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 6th case:
      # seq1 s1------e1
      # seq2 s2---------------e2
      if (($s1 == $s2) && ($e1 < $e2) && ($flag == 0))  {
        print "6i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "6j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 7th case:
      # seq1 s1---------------e1
      # seq2 s2------e2
      if (($s1 == $s2) && ($e1 > $e2) && ($flag == 0))  {
        print "7i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "7j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 8th case:
      # seq1          s1------e1
      # seq2 s2---------------e2
      if (($s1 > $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "8i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "8j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }

      # 9th case:
      # seq1 s1---------------e1
      # seq2           s2-----e2
      if (($s1 < $s2) && ($e1 == $e2) && ($flag == 0))  {
        print "9i\t",$i,"-",$j,"\t",$a[$i]{line},"\n";
        print "9j\t",$i,"-",$j,"\t",$a[$j]{line},"\n";
        $flag=1;
      }
    }
  }
}
