#!perl -w
use Cwd;
use warnings;
use strict;
use Net::FTP;
use File::Copy;
use File::Path;
use File::Find::Rule;
use Time::Local;
use File::Basename;
use Path::Class;
use Mail::Sender;
use CMS::MediaWiki;
use Getopt::Long;

#use vars qw[%mail];
#use Net::SMTP;
#C:/strawberry/perl/site/lib/Mail/Sender.config

my $dir = getcwd;
my $InDir1 = "$dir/Release_BTH_GPRS";
my $InDir2 = "$dir/Release_WLAN_GPRS";
my $Version;
my $BuildError = 0;
my %filesize;
my %totalfilesize;
my $OutPath = "//ark/software/Releases/CBA3x00/";
#my $OutPath = "C:/tmp/";  #For debugging only!
my @EmailMessageText;
my $omitversion = 0;
my $help = 0;

GetOptions ("saida|s=s"   	=> \$OutPath,		# string
			"omitversion|o"	=> \$omitversion,	# numeric
            "help|h"		=> \$help,			# flag
			);
if( $help )
{
       print("Opcoes para ExportaHexa.pl:\n");
	   print("-omitversion -o\t\t\tNao busca versao no arquivo, perguntar numero de versao para o usuario\n");
       #print("-version -v [3100|3200|PLM|ETD]\tCompilar as versões indicadas\n");
       #print("-modelo -m [WLAN|Bluetooth]\tCompilar os modelos indicadas\n");
       print("-saida -s [Pasta de saida]\tMuda pasta de saida para a indicada\n");
       exit;
}

#Verifica que o caminho de saida termina com / ou \
my $LastChar = substr( $OutPath, -1);
if(( $LastChar ne '/' ) && ( $LastChar ne '\\' ))
{
       #Não termina, então força o caminho terminar com /
       $OutPath = $OutPath . "/";
}

#Checa arquivos de log
print("Verificando build logs para erros:\n");
my @file = glob("*.LOG");
foreach (@file)
{
	my ($volume,$directories,$filename) = File::Spec->splitpath( $_ );
	print("$filename:\t");
	my ($buildErro, $buildWarning) = CheckBuildError($_);
	if(( $buildErro eq 0) and ( $buildWarning eq 0))
	{
		print("OK!\n");
	}
	elsif(( $buildErro eq 0) and ( $buildWarning eq 1))
	{
		system("notepad++ $filename");
		print("OK mas com warnings\n");
	}	
	else
	{
		#Open logfile for user to inspect errors
		system("notepad++ $filename");
		print("Error de compilacao\n");
		$BuildError = 1;
	}
}
#Se deu erro no checagem, não precisa continuar
if( $BuildError eq 1 ) { exit; }

#Try and get version number
if( !$omitversion )
{
	$Version = GetVersionNumber();
	if( !defined $Version )
	{
		print("Versao de firmware nao encontrado!\n");
		#Pede a versão do usario
		$omitversion = 1;
	}
}
if( $omitversion )
{
	print("Entra nome da versao para gerar (enter sem texto para cancelar): ");
	chomp($Version = <STDIN>); #Prompt for version of Firmware
	if( !defined $Version )
	{
		print("Cancelado.\n");
		exit; 
	}
}
print("Versao $Version encontrado\n");

$OutPath = $OutPath . "$Version/";
my $Path = dir($OutPath);
print("Copiando arquivos .hex de $dir para $OutPath\n");

if (-d $OutPath) {
	#Seta valor do string sendo outro que s, n, S, ou N
	my $Overwrite;
	print("Pasta de saida existe.  Voce quer sobrepor os arquivos mesmo (S/N)?");
	chomp($Overwrite = <STDIN>); #Prompt for version of Firmware
	my @chars = split("", $Overwrite);
	if(!(( $chars[0] eq 's' ) || ( $chars[0] eq 'S' )))
	{
		print("Terminando processo\n");
		exit;
	}
}

#Cria caminho se não existe
$Path->mkpath;
#copia os arquivos dos dois caminhos
%filesize = CopyFiles( $InDir1, $OutPath );
%totalfilesize = %filesize;
%filesize = CopyFiles( $InDir2, $OutPath );
@totalfilesize{keys %filesize} = values %filesize;

foreach my $name (sort keys %totalfilesize)
{
	@EmailMessageText = (@EmailMessageText, "$name (Tam $totalfilesize{$name} bytes)");
}

#copy log files
print("Copiando arquivos de log\n");
$dir = getcwd;
@file = glob("*.LOG");
foreach (@file)
{
	copy( $_, $OutPath ) or die "$!";
}

GenerateEmailText();

#--------- FIM

sub CopyFiles 
{
	my($InDir, $OutDir) = @_;
	
	my %filesize;
	my $TempFilename;
	
	#Para cada arquivo do tipo .hex encontrado
	foreach my $file (find->file()->name('*.hex')->in($InDir))
	{
		#Quebra o nome do arquivo em suas partes
		my ($volume,$directories,$filename) = File::Spec->splitpath( $file );
		#Forma caminho original 
		my $path = $directories . $filename;
		$_ = $filename;
		s/X.X.X/$Version/; # Rename file
		$TempFilename = $_;
		#forma novo caminho
		my $newpath = $OutDir . $TempFilename;
		#print("copy $newpath\n");
		copy( $path, $newpath ) or die "$!";
		#Adiciona nome de arquivo e seu tamanho num hash
		$filesize{$TempFilename} = -s $file;
	}
	return %filesize;
}

sub CheckBuildError
{
	my($file) = @_;
	my $BuildErro = 1;	#seta erro de build
	my $BuildWarn = 1;	#seta warnings no build
	open FILE, "<", $file or die $!;
	#Procura linha por linha do arquivo...
	while (<FILE>) 
	{
		#Procura para o string identificando que não ocorreu nenhum erro
		if( /Total number of errors: 0/)
		{
			$BuildErro = 0;
		}
		#Procura para o string identificando que não ocorreu nenhum warning
		if( /Total number of warnings: 0/)
		{
			$BuildWarn = 0;
		}		
	}
	close(FILE);
	return ($BuildErro, $BuildWarn);
}

sub GetVersionNumber
{
	my $Version;
	my $Revision;
	my $Build;
	open FILE, "<", "controle.c" or die $!;
	#Procura linha por linha do arquivo...
	while (<FILE>) 
	{
		#Procura versão
		$Version = $1	if( /#define CBA_VERSAO\s+(\d+)/);

		#Procura Revisão
		$Revision = $1	if( /#define CBA_REVISAO\s+(\d+)/);

		#Procura Build
		$Build = $1		if( /#define CBA_BUILD\s+(\d+)/);
	}
	close(FILE);
	if(( !defined $Version ) || ( !defined $Revision ) || ( !defined $Build ))
	{
		return;
	}
	return("$Version.$Revision.$Build");
}

#sub SendReleaseEmail
sub GenerateEmailText
{
	my $Msg2 = join("\n", @EmailMessageText);
	#print $Msg2;  #Isso escreve só as informações dos arquivos gerados
	my $MsgTitle = "Release $Version";
	my $Msg = "\n====\n\nPrezados colegas,\n\nSegue a relatorio de build para a versao $Version disponivel na pasta $OutPath.  Segue os tamanhos dos arquivos gerados:\n\n$Msg2\n\nRelease notes:\n\n[Colar Release notes aqui]\n====\n";
	print $Msg;
	#A seguinte seria legal assim que termina a busca dos release notes do wiki..
	#E se conseguir usar a usuario e senha do servidor smtp global...
	#my $sender = new Mail::Sender {
    #        auth 	=> 'PLAIN',
    #        authid 	=> '',
    #        authpwd => '',
    #        smtp 	=> 'smtp.sao.terra.com.br',
    #        port 	=> 587,
    #        from 	=> 'karl.stiller@auteq.com.br',
    #        to 		=> 'karl.stiller@auteq.com.br',
    #        subject => $MsgTitle,
    #        #msg 	=> 'Test Message Script',
	#		msg 	=> $Msg
    #};

    #my $result =  $sender->MailMsg({
    #        msg => $sender->{msg},
    #        #file => $sender->{file},
    #});
}

sub GetLatestChanges
{
	my $i;
	print( "Pt 1\n");
	my $mw = CMS::MediaWiki->new(
		# protocol => 'https',  # Optional, default is http
		host  => 'http://ark.gfexplorer.com.br/',   # Default: localhost
		#path  => 'wiki' ,       # Can be empty on 3rd-level domain Wikis
		debug => 0              # Optional. 0=no debug msgs, 1=some msgs, 2=more msgs
	);
	print( "Pt 2\n");
	my $lines_ref = $mw->getPage(title => 'Página_principal', section => 1); # omit section to get full page
	
	# Process Wiki lines ...
	print sprintf('%08d ', ++$i), " $_\n" foreach @$lines_ref;
}


