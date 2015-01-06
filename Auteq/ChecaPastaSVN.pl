#!perl -w
use warnings;
use strict;

my $svnStatus;
my @modifiedFiles;

#Gerar um arquivo com o estado da pasta
system( 'svn status > status.out' );

open( my $status, "<", "status.out" ) 
	or die "cannot open < status.out: $!";

while (my $statusLine = <$status>) {
	if( $statusLine =~ /^[M]\s+(\S+)/ )
	{
		push( @modifiedFiles, "$1" );
	}	
}
close( $status );

#apaga o arquivo temporario
unlink "status.out";

if (@modifiedFiles > 0)
{
	my $continue;
	my $modifiedFiles = join( "\n", @modifiedFiles );
	print( "Erro: Arquivos modificados comparados com o repositorio!\n" );
	print( "$modifiedFiles\n" );
	print( "Desejo continuar a compilacao? (S/N):");
	chomp($continue = <STDIN>); #Da o controle para o usario.
	my @chars = split("", $continue);
	if(!(( $chars[0] eq 's' ) || ( $chars[0] eq 'S' )))
	{
		exit 1;
	}
	exit 0;
}
exit 1;