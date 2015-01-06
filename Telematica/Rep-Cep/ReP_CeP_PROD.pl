#!perl -w
# A perl script to try and automate the generation of .hex files and .bin for production.

BEGIN {
	print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
	$| = 1;
}

use strict;
use Win32::GuiTest qw(:ALL);
$Win32::GuiTest::debug = 0; # Set to "1" to enable verbose mode
use File::Copy;
use Cwd;
use Fcntl;                          # for SEEK_SET and SEEK_CUR
use Getopt::Long;
#use vars qw/ %opt /;
require "Env.pl";

#my $PROG_PATH ="C:/ARQUIV~1/Hi-Lo/ALL-11/";
#my $PROG_NAME = "WACCESS.EXE";
#my $TEST_DIR = "E:/Acesso_Oracle/18.4.0/";
#my $HEX_PATH = "objects\\";
#my $HEX_FILENAME = "codinarm.hex";
#my $BACKUP_BIN_FILENAME = "codinarm.bin";
#my $OUTPUT_FOLDER = "Install";
our $PROG_PATH;
our $PROG_NAME;
our $TEST_DIR;
our $HEX_PATH;
our $HEX_FILENAME;
our $BACKUP_BIN_FILENAME;
our $OUTPUT_FOLDER;

my $FORMAT = 'C C C C';
my @DATA = (0x50, 0x6E, 0x20, 0xB9);
my @CHECK_DATA = (0x00, 0x00, 0xA0, 0xE1);
my $OUT_PATH;
my $OUT_NAME;
my $OUT_NAME_RAW;
my @OUT_NAME_LIST;
my $buffer;
my $fileopt;
my $test_flag;
my $help_flag;

#get command line options
GetOptions("t" =>\$test_flag,
		   "o:s" =>\$fileopt,
		   "h" =>\$help_flag);
		   
if ($help_flag)
{
	help_screen();
	exit;
}		   

#open config file if it was given, else ask for filename.
if ($fileopt)
{
	# read in entire file
	open FILE, "$fileopt" or die "Config file \'$fileopt\' not found!\n";
	my @config_file = <FILE>;
	$OUT_NAME_RAW = $config_file[0];
	chomp $OUT_NAME_RAW;
	# get output filename removing any '.'s accidenally typed.
	@OUT_NAME_LIST = split /\./, $OUT_NAME_RAW;
	$OUT_NAME = $OUT_NAME_LIST[0];	
}
else
{
	# get output filename removing any '.'s accidentally typed.
	print("Digite o nome de arquivo desejado:");
	$OUT_NAME_RAW = <STDIN>;
	chomp $OUT_NAME_RAW;
	@OUT_NAME_LIST = split /\./, $OUT_NAME_RAW;
	$OUT_NAME = $OUT_NAME_LIST[0];
}

#get and generate local and output paths
my $desk = GetDesktopWindow();
my $LOCAL_PATH = cwd();
chomp $LOCAL_PATH;
$LOCAL_PATH =~ s#\/#\\#g;	# regular expression to change all '/'s to '\'s - cant use '/'s in the window entry.
$LOCAL_PATH = $LOCAL_PATH . "\\"; # add \, ready to add the filenames afterwards
if ($test_flag)
{
	$OUT_PATH = $TEST_DIR;
}
else
{
	$OUT_PATH = $LOCAL_PATH . "$OUTPUT_FOLDER\\";
}

print("\nCreating file: $OUT_NAME\n");

# Open WACCESS if it isn't already open 
# This might not always work....
# best (and faster!) when program is already open.

my (@converter_windows) = FindWindowLike($desk, "ALL-11 Universal Programmer", "");
my @dialog_error_windows;
my $window;
if (not @converter_windows)
{
	chdir "$PROG_PATH";
	system("cmd /c start $PROG_NAME");
	@converter_windows = WaitWindowLike($desk, "ALL-11 Universal Programmer", "");
	sleep(5);
	SendKeys("{ENTER}");
}

if (get_window_focus($desk, "ALL-11 Universal Programmer"))	# Make sure the user didnt get bored and change window focus
{	
	open_utility();			# abrir o programa de conversor de hex
	enter_file_details();	# colocar os detalhes para gerar o bin.
	sleep(1);
	find_press_text($dialog_error_windows[0], "Start");
	sleep(3);				# wait for conversion process.
	SendKeys("{ENTER}");
	find_press_text($dialog_error_windows[0], "Close");
	sleep(1);

	# Copy hex and bin files to output location
	copy("$LOCAL_PATH$HEX_PATH$HEX_FILENAME", "$OUT_PATH$OUT_NAME.hex"); 
	copy("$LOCAL_PATH$HEX_PATH$BACKUP_BIN_FILENAME", "$OUT_PATH$OUT_NAME.bin");

	# Edit arquivo .bin
	if (check_bin_file("$OUT_PATH$OUT_NAME.bin", 0x14, $FORMAT, @CHECK_DATA))
	{
		edit_bin_file ("$OUT_PATH$OUT_NAME.bin", 0x14, $FORMAT, @DATA);
	}
	else
	{
		print("Erro editando arquivo\n");	
	}
	print("Arquivos gravados em $OUT_PATH\n");
}

####################### Start Subroutines ###############################################
sub get_window_focus
{
	my ($window_parent, $window_name) = @_;
	
	my @windows = WaitWindowLike($window_parent, $window_name, "");
	if (@windows)
	{
		my ($window) = @windows;
		if (IsWindow($window))
		{
			SetForegroundWindow($window);
		}
	}
	(@windows);	# return handle to calling program.
}

sub open_utility
{
	SendKeys("%u"); #ALT+u
	SendKeys("0");
}

sub enter_file_details
{
	SendKeys("$LOCAL_PATH$HEX_PATH$HEX_FILENAME");
	SendKeys("{TAB}");
	SendKeys("$LOCAL_PATH$HEX_PATH$BACKUP_BIN_FILENAME");
	find_press_text($desk, "FFH");
}

sub find_press_text
{
	my ($window_child, $text) = @_;
	my ($window_text) = FindWindowLike($window_child, "$text");
	if ($window_text)	#janela achado
	{
		my ($wx, $wy) = GetWindowRect($window_text);
		MouseMoveAbsPix($wx+5,$wy+5);
		SendLButtonDown();
		SendLButtonUp();
	}
}

sub check_bin_file
{
	my ($bin_file, $position, $format, @data) = @_;
	my $RECSIZE = length pack($format, () ); #ler 4 caractares
	my $READSIZE;
	my $error = 0;
	
	print("Verificando arquivo\n");
	open(IN_BIN, '+<', "$bin_file") or die "$bin_file not found! $!"; 
	binmode(IN_BIN);
	
	#mudar para o endereço para editar
	seek(IN_BIN, $position, 0) or die "Seeking: $!";	#0 = SEEK_SET
	$READSIZE = read(IN_BIN, $buffer, $RECSIZE);
	
	if ($READSIZE ne $RECSIZE) {
		die "Reading: $!";
	}
	#criar um array para confirmar o contuido e editar os valores
	my (@FIELDS) = unpack($format, $buffer);
	my $counter;
	my $limit = @data;

	for ($counter = 0; $counter < $limit; $counter++)
	{
		if ($FIELDS[$counter] eq $data[$counter])
		{
			$error++;
		}
	}
	if ($error ne $limit) 
	{
		print("Formato errado\n");
		$error = 0;
		return ($error);
		exit;
	}
	return ($error);
}

sub edit_bin_file
{
	my ($bin_file, $position, $format, @data) = @_;
	
	my $RECSIZE = length pack($format, () ); #ler 4 caractares
	my $READSIZE;
	
	print("Editando o arquivo .bin\n");
	open(IN_BIN, '+<', "$bin_file") or die "$!"; 
	binmode(IN_BIN);
	
	#mudar para o endereço para editar
	seek(IN_BIN, $position, 0) or die "Seeking: $!";	#0 = SEEK_SET
	$READSIZE = read(IN_BIN, $buffer, $RECSIZE);
	
	if ($READSIZE ne $RECSIZE) {
		die "Reading: $!";
	}
	#criar um array para confirmar o contuido e editar os valores
	my (@FIELDS) = unpack($format, $buffer);
	my $counter;
	my $limit = @data;
	# editar os valores.
	for ($counter = 0; $counter < $limit; $counter++)
	{
		$FIELDS[$counter] = $data[$counter];
	}
	
	#muda de volta para uma lista.
	$buffer = pack($format, @FIELDS);
	
	#mudar de volta para o começo do endereço para editar
	seek(IN_BIN, -$RECSIZE, 1)       or die "Seeking: $!"; #1 = SEEK_CUR
	
	#escrever por cima dos bytes antigos.
	print IN_BIN $buffer;
	close IN_BIN                            or die "Closing: $!";	
}

sub help_screen
{
	print ("-----------------------------------------------------------\n");
	print ("Rep/Cep script para a producao dos arquivos .bin e .hex\n");
	print ("Feito para gerar os arquivos apartir do compilador\n\n");
	print ("Opcoes:\n");
	print ("-o [filename] \tDefine o nome para os arquivos de saida (.bin e .hex)\n\n");
	print ("-t \t\tExecutar o script no modo de test. Os arquivos vao ser gerado\t\t\tno path definido no variavel " .'$TEST_DIR.' . "\n\n");
	print ("-h \t\tMostar este mensagem.\n\n");
	print ("e.g: perl $0 -o ReP010001E -t\n");
	print ("-----------------------------------------------------------\n");
}
