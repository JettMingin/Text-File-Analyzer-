#!/usr/bin/perl

use v5.34;
use strict;
use warnings;
use Text::SimpleTable::AutoWidth;
use Term::ExtendedColor qw(:all);

my $pastedtext;
my @textdoc;

if($ARGV[0] =~ /-p/){
    if ($ARGV[1]){
        $pastedtext = pastedTextCheck($ARGV[1]);
        chomp(@textdoc = split("\n", $pastedtext));
    }else{
        die "Argument '-p' should be followed with your desired text within double-quotes";
    }
}else{
    open FILE, "$ARGV[0]" or die "No file found";
    chomp(@textdoc = <FILE>);
    close FILE;
}

my @words;
my @sans_stopwords;
my $line_count = 0;
my $char_count = 0;
my $word_count = 0;
my %unique_words;

#making sure the pasted text was within double-quotes
sub pastedTextCheck{
    if ($_[0] !~ /\s+/){
        die fg('red1', "[TFA: REMEMBER TO PUT DOUBLE-QUOTES AROUND YOUR TEXT]");
    }else{
        return ($_[0]);
    }
}

#SORT SUB unique words in order of apperance 
sub by_frequency{
    $unique_words{$b} <=> $unique_words{$a} or $a cmp $b
}

sub averageWordLength{
    my @words = @_;
    my $count = ($#words + 1);
    my $totalchars;

    foreach (@words){
        $totalchars += length($_);
    }

    return($totalchars/$count);
}

sub largestSmallest{
    my @words = @_;
    my $large = 'a';
    my $small = '$words[0]';

    foreach (@words){
        if (length($_) > length($large)){
            $large = $_;
        }elsif(length($_) < length($small)){
            $small = $_
        }
    }
    return($large, $small);
}

#INITIAL PROCESSING of the document  - convert each line to lowercase, count chars, remove punctuation, count words, and count lines
#STORING EVERY WORD as an element in '@words'
foreach my $i (0..$#textdoc){ 
    my $processed_line = lc($textdoc[$i]);
    $char_count += length($processed_line);
    $processed_line =~ s/[\.\,\-\;\:\'\"\!\?]//g;
    $word_count += split(/\s+/, $processed_line);
    $line_count ++;
    push @words, split(' ', $processed_line);
}

my @stop_words = qw( a an and as be but by for from if in is it its of on or the this that they their there to was will with you );
#removing stop words defined above - replacing each stop word in the array "@words" with the word "STOPWORD"
foreach my $i (0..$#words){
    foreach (@stop_words){      #nested loop, could be improved?
        if ($words[$i] eq $_){
            splice @words, $i, 1, 'STOPWORD';
        }
    }
}

my $total_stopwords = 0;
#building hash counting each apperance of every unique word - also counting total number of stopwords identified
foreach my $i (0..$#words){
    if ($words[$i] eq 'STOPWORD'){
        $total_stopwords ++;
    }else{
        $unique_words{$words[$i]}++;
        push @sans_stopwords, $words[$i];
    }
}

#'@frequency' stores 1 instance of all unique words, sorted by frequency of appearances in the text file
my @frequency = sort by_frequency(keys(%unique_words)); 

#'$frequent_word_table' is built here, a table containing the 10 most frequent words used in the doc
my $frequent_word_tbl = Text::SimpleTable::AutoWidth->new();
$frequent_word_tbl->captions(['Word', 'Frequency']);
foreach my $i(0..9){
    $frequent_word_tbl->row("$frequency[$i]", $unique_words{$frequency[$i]});
}

print fg('springgreen1', "Text Analysis of $ARGV[0]\n");

#print line/word/char counts in table
my $count_table = Text::SimpleTable::AutoWidth->new();
$count_table->captions(['Lines', 'Words', 'Chars']);
$count_table->row( $line_count, $word_count, $char_count );
print $count_table->draw;

printf ("\nA total of %d stop words identified. (%d%% of total words)\n", $total_stopwords, (($total_stopwords/$word_count)*100));

#print the table containing the 10 most common words
say "(Excluding common stop words from here on out...)\n";
print fg('springgreen1', "   10 Most-used words\n");
print $frequent_word_tbl->draw();

#calculating the average word length in the doc (not taking stopwords into account)
my $avg_word_length = averageWordLength(@sans_stopwords);
printf ("The average word length is %.2f letters\n", $avg_word_length);

#identifying the largest and smallest word appearing in the doc (not counting stopwords)
my ($largest, $smallest) = largestSmallest(@sans_stopwords);
say "The largest word is: $largest, and the smallest: $smallest";

