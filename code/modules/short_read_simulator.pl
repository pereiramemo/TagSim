#!/usr/bin/perl

use Getopt::Long qw(GetOptions);

###############################################################################
### 1 - Define flags
###############################################################################

GetOptions(
'input_file=s' => \$INPUT_FILE,
'output_file=s' => \$OUTPUT_FILE,
'read_length=i' => \$K,
'slide_window=i' => \$W,
'error_rate=f' => \$E
);

###############################################################################
### 2 - Get input and output
###############################################################################

open($IF,$INPUT_FILE) or die "no input file privided";
open($OF, '>', $OUTPUT_FILE) or die "no output file privided";

###############################################################################
### 3 - Define defaults
###############################################################################

if (!$E) {
  $E = 0.001;
}

if (!$K) {
  $K = 100;
}

if (!$W) {
  $W = 50;
}

###############################################################################
### 4 - Define error function
###############################################################################

sub add_error {
  my ($input_seq, $header,$K) = @_;

  # select a random position in sequence read
  $random_position = int(rand($K));
  
  # define possile error nucleotides
  $nucl = substr($input_seq, $random_position, 1);
  @nucl_all = ("A","T","G","C");
  @nucl_comp = grep { ! /$nucl/ } @nucl_all;

  # add error 
  $random_index = int(rand(3));
  $random_nucl = $nucl_comp[$random_index];
  $output_seq = $input_seq;
  substr($output_seq, $random_position, 1, $random_nucl);

  # add error into into header
  $header = $header."-pos-".$random_position."-".$nucl."->".$random_nucl;

  # $output_test = $input_seq."\n".$output_seq."\n".$random_nucl."\t".$k."\t".$random_index."\t".$random_position;
  @output = ($header, $output_seq);
  return @output;
}

###############################################################################
### 5 - Parse input file
###############################################################################

while (<$IF>) {

  # get header
  if (/(^>.*$)/) {
    $header=$1;
  } else {

  # get sequence
  $seq=$_;
  chomp $seq;
  $seq_hash{$header} = $seq_hash{$header} . $seq ;

  }
}

###############################################################################
### 6 - Generate short reads
###############################################################################

@nucl_all = ("A","T","G","C");
$counter=0;
foreach $key (keys %seq_hash) {

  $l = length($seq_hash{$key});
  $seq = $seq_hash{$key};

  if ($l >= $K) {

    $end = $l -$K;
    $i = 0;
    while ($i <= $end) {

      $short_read = substr($seq, $i, $K);
      $header = $key."|".$i."-length-".$K;
      #print $label,"\n",$short_read,"\n";
      $i = $i + $W;

      # add error every 1000 nucletides
      if ($counter >= 1/$E) {
        @output = add_error($short_read, $header, $K);
        $header = $output[0];
        $short_read = $output[1];
        $counter = 0;
      }

      $counter = $counter + $K;
      print $OF $header,"\n",$short_read,"\n";
    }
  } else {

  $random_seq_length = $K -$l;
  @numbers = (1 .. $random_seq_length);
  $random_seq = join("", @nucl_all[ map { rand @nucl_all } @numbers ]);
  $short_read = $seq.$random_seq;
  $header = $key."|"."random_added_seq-length-".$random_seq_length;

  if ($counter >= 1/$E) {
        @output = add_error($short_read, $header, $random_seq_length);
        $header = $output[0];
        $short_read = $output[1];
        $counter = 0;
      }

      $counter = $counter + $K;
      print $OF $header,"\n",$short_read,"\n";
  }
}

close $OF;
