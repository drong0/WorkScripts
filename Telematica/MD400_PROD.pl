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
use Getopt::Long;

require "Env.pl";

#my $PROG_PATH ="C:/ARQUIV~1/Hi-Lo/ALL-11/";
#my $PROG_NAME = "WMEM1.EXE";
#my $TEST_DIR = "E:/Acesso_Oracle/18.4.0/";
#my $HEX_FILENAME = "projetoflash.hex";
#my $TEMP_BIN_FILENAME = "out.bin";	# a aplicativo as vezes não salva com o nome correto 
#my $BACKUP_BIN_FILENAME = "projetoflash.bin";
#my $OUTPUT_FOLDER = "Hex";
our $PROG_PATH;
our $PROG_NAME;
our $TEST_DIR;
our $HEX_FILENAME;
our $TEMP_BIN_FILENAME;
our $BACKUP_BIN_FILENAME;
our $OUTPUT_FOLDER;
#system ("perl env.pl");

my $OUT_PATH;
my $OUT_NAME_RAW;
my @OUT_NAME_LIST;
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
	# get output filename removing any '.'s accidenally typed.
	@OUT_NAME_LIST = split /\./, $fileopt;
	$fileopt = $OUT_NAME_LIST[0];
}
else
{
	# get output filename removing any '.'s accidentally typed.
	print("Digite o nome de arquivo desejado:");
	$OUT_NAME_RAW = <STDIN>;
	chomp $OUT_NAME_RAW;
	@OUT_NAME_LIST = split /\./, $OUT_NAME_RAW;
	$fileopt = $OUT_NAME_LIST[0];
}

#get and generate local and ouput paths
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
	my @OUT_PATH_LIST = split m#\\#, $LOCAL_PATH;
	my $path_count = @OUT_PATH_LIST;
	$path_count -= 2;
	$OUT_PATH = join "\\", @OUT_PATH_LIST[0..$path_count];
	$OUT_PATH .= "\\$OUTPUT_FOLDER\\";
}

print("\nCreating file: $fileopt\n");

# Open WMEM1 if it isn't already open 
# This might not always work....
# best (and faster!) when program is already open.

my (@converter_windows) = FindWindowLike($desk, "WMEM1", "");
my @dialog_error_windows;
my $window;
if (not @converter_windows)
{
	print("\n");
	system("cmd /c start $PROG_PATH$PROG_NAME");
	@converter_windows = WaitWindowLike($desk, "WMEM1", "");
	sleep(2);
	if (get_window_focus($desk, "Programmer Status"))	# Make sure the user didnt get bored and change window focus
	{
		SendKeys("{ENTER}");
	}
	
	sleep(40);
	if (get_window_focus($desk, "Programmer Status"))	# Make sure the user didnt get bored and change window focus
	{
		SendKeys("{ENTER}");
	}
	sleep(5);	
}

if (get_window_focus($desk, "WMEM1"))	# Make sure the user didnt get bored and change window focus
{
	# Load Hex file
	load_hex_file();

	# Set input format
	@dialog_error_windows = WaitWindowLike($desk, "File Format", "");
	SendKeys("{UP}{UP}{UP}{UP}{UP}{UP}{UP}"); # Make sure we are on the first format after this operation.
	SendKeys("{DOWN}");
	find_press_text($dialog_error_windows[0], "FF");
	find_press_text($dialog_error_windows[0], "OK");

	#Wait for program to load file
	sleep(10);
}

if (get_window_focus($desk, "WMEM1"))	# Make sure the user didnt get bored and change window focus
{
	#Save Ouput File
	save_bin_file();

	#Save Finally
	@dialog_error_windows = WaitWindowLike($desk, "Save buffer to file", "");
	find_press_text($dialog_error_windows[0], "OK");
	
	#wait for file to be saved
	sleep(2);
	
	# Copy hex and bin files to output location
	copy("$LOCAL_PATH$HEX_FILENAME", "$OUT_PATH$fileopt.hex"); 
	copy("$LOCAL_PATH$TEMP_BIN_FILENAME", "$OUT_PATH$fileopt.bin");
	
	# Rename local bin file to normal name (Backup copy along with original hex file)
	move("$LOCAL_PATH$TEMP_BIN_FILENAME", "$LOCAL_PATH$BACKUP_BIN_FILENAME");
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

sub load_hex_file
{
	SendKeys("%F"); #ALT+F
	SendKeys("L");
	sleep(1);
	SendKeys("$LOCAL_PATH$HEX_FILENAME");
	SendKeys("{ENTER}");
}

sub save_bin_file
{
	SendKeys("%F"); #ALT+F
	SendKeys("S");
	SendKeys("$LOCAL_PATH$TEMP_BIN_FILENAME");
	SendKeys("{ENTER}");
	# check if file already exists and it opened a dialog window
	my @windows = FindWindowLike(0, "Save File");
	my $no_windows = @windows;
	if ($no_windows > 1)
	{		
		SendKeys("{TAB}{ENTER}");
	}
	SendKeys("{ENTER}");
}

sub find_press_text
{
	my ($window, $text) = @_;
	my ($window_text) = FindWindowLike($window, "$text");
	if ($window_text)	#window found
	{
		my ($wx, $wy) = GetWindowRect($window_text);
		MouseMoveAbsPix($wx+5,$wy+5);
		SendLButtonDown();
		SendLButtonUp();
	}
}

sub help_screen
{
	print ("-----------------------------------------------------------\n");
	print ("MD400 script para a producao dos arquivos .bin e .hex\n");
	print ("Feito para gerar os arquivos apartir do compilador Zilog\n\n");
	print ("Opcoes:\n");
	print ("-o [filename] \tDefine o nome para os arquivos de saida (.bin e .hex)\n\n");
	print ("-t \t\tExecutar o script no modo de test. Os arquivos vao ser gerado\t\t\tno path definido no variavel " .'$TEST_DIR.' . "\n\n");
	print ("-h \t\tMostar este mensagem.\n\n");
	print ("e.g: perl $0 -o MD045816 -t\n");
	print ("-----------------------------------------------------------\n");	
}
