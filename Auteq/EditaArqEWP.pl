#!perl -w
use warnings;
use strict;
use XML::LibXML;

# perl script para gerar novos arquivos de projeto tipo .ewp do IAR com customizações nos seguintes lugares:
# 1. Defines no Preprocessor do C Compiler.
# 2. Nome do arquivo .hex gerado.

#define nomes de arquivo padrão
my $PrjFile3100 = "cpu3100.ewp";
my $PrjFile3200 = "cpu3200.ewp";
my $PrjFileETD  = "cpu3200_etd.ewp";
my $PrjFilePLM  = "cpu3200_plm.ewp";

#define opções para adiciona nos projetos - para mais que uma opção define ("Opt_1", "Opt_2",..., "Opt_x")
my @GPSCompileOptions = ("DEBUG_GPS");
my @CECCompileOptions = ("SIMULADOR_CAN_GPS");

#define como vai chamar o prefixo para os arquivos de: projeto, e hex
my $GPSPrefixName = "DEBUG_GPS";
my $CECPrefixName = "TESTE_CEC";

#define os nomes dos arquivos baseado no nome do arquivo do projeto original.
#GPS
(my $GPSPrjFile3100 = $PrjFile3100) =~ s/\./_$GPSPrefixName./;
(my $GPSPrjFile3200 = $PrjFile3200) =~ s/\./_$GPSPrefixName./;
(my $GPSPrjFilePLM  = $PrjFilePLM ) =~ s/\./_$GPSPrefixName./;
(my $GPSPrjFileETD  = $PrjFileETD ) =~ s/\./_$GPSPrefixName./;

#CEC
(my $CECPrjFile3100 = $PrjFile3100) =~ s/\./_$CECPrefixName./;
(my $CECPrjFile3200 = $PrjFile3200) =~ s/\./_$CECPrefixName./;
(my $CECPrjFilePLM  = $PrjFilePLM ) =~ s/\./_$CECPrefixName./;

#cria novos arquivos de projeto para facilitar a compilação
#GPS
EditProjectFile( $PrjFile3100, $GPSPrjFile3100, $GPSPrefixName, @GPSCompileOptions );
EditProjectFile( $PrjFile3200, $GPSPrjFile3200, $GPSPrefixName, @GPSCompileOptions );
EditProjectFile( $PrjFilePLM,  $GPSPrjFilePLM,  $GPSPrefixName, @GPSCompileOptions);
EditProjectFile( $PrjFileETD,  $GPSPrjFileETD,  $GPSPrefixName, @GPSCompileOptions );

#CEC
EditProjectFile( $PrjFile3100, $CECPrjFile3100, $CECPrefixName, @CECCompileOptions );
EditProjectFile( $PrjFile3200, $CECPrjFile3200, $CECPrefixName, @CECCompileOptions );
EditProjectFile( $PrjFilePLM,  $CECPrjFilePLM,  $CECPrefixName, @CECCompileOptions);

sub EditProjectFile
{
	my( $fileParent, $fileChild, $filePrefix, @compileOp ) = @_;
	#print("arquivo original $fileParent\n");
	print("Gerando projeto novo $fileChild\n");
	#print("prefix dos arquivos $filePrefix\n");
	#print("opcoes de compilacao @compileOp\n\n");
	
	my $parser = XML::LibXML->new( "1.0", "iso-8859-1" );
	my $doc = $parser->parse_file( $fileParent );
	my $root = $doc->getDocumentElement();
	
	#Achar nível onde a modificação precisa entrar
	for my $sample ($doc->findnodes('/project/configuration/settings/data/option'))
	{
		#Encontrou o lugar correto?
		my ($id) = $sample->findvalue('name');
		if( $id eq "CCDefines")
		{
			#Adiciona os elementos novos
			for( my $i = 0; $i < @compileOp; $i++)
			{
				$sample->appendTextChild( "state", $compileOp[$i] );
			}
		}
	}
	#Trocar nome do arquivo de saida
	for my $sample2 ($doc->findnodes('/project/configuration/settings/data/option/state'))
	{
		#if ($sample2 =~ /.X.X.X./)
		if ($sample2 =~ /\.X\.X\.X\.\D+\.hex/)
		{
			#Modifica o nome do arquivo hex.
			my $hexFile = $sample2->textContent;
			$hexFile =~ s/\.X\.X\.X\./.X.X.X.$filePrefix./;
			$sample2->removeChildNodes();
			$sample2->appendText( $hexFile );
		}
	}
	#Passar modificações para arquivo de saida.
	$doc->toFile( $fileChild, 1);
}