package NewBackend;
use JSON::XS;
use Data::Dumper;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(process_request);
my @catalog_json; # Каталог, заполненный из файла catalog.json
my @catalog; # Структурированный каталог
my @catalog_position_user_json; # Каталог с пользователями и их заказами

open FILEWORK, "<", "catalog.json" or die "Ошибка открытия файла catalog.json: $!\n";
# Если да, установить $/ значение undef
$/ = undef;
# Объявить переменную для хранения
# декодированных данных из файла JSON
@catalog_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
# Закрыть файловый дексриптор
close FILEWORK;

my $i = 0;
while ( $catalog_json[0]->[$i] ) {
	$catalog[$i] = $catalog_json[0]->[$i];
	$i++;
}

# Функция разбирает url и вызывает соотвествующе функции
sub process_request {

	my ($url) = @_;
    my @array_patch = split /\//, $url;
	my $size_array_patch = @array_patch;

	if ( $array_patch[1] eq "catalog" ) {
		if ( !$array_patch[2] ) {
			print "Вывод каталога \n";
			return @catalog;
		}
		elsif ( !$array_patch[3] ) {
			print "Вывод каталога с сортировкой по автору \n";
			return sort_for_author($array_patch[2]);
		}
		elsif ( $array_patch[3] eq "date_asc" ){
			print "Вывод каталога с сортировкой по дате \n";
			return sort_for_date( sort_for_author( $array_patch[2] ) );
		}
	}
	elsif ($array_patch[1] eq "orders" and !$array_patch[3]) {
		print "Вывод заказов юзера \n";
		return position_user($array_patch[2]);
	}
	elsif ( $array_patch[1] eq "orders" and $array_patch[3] eq "new" ) {
		return save_position_user( $array_patch[2], $array_patch[4] );
	}
    else {
    	return 0; 
    }
}

sub sort_for_author {
	my($author) = @_;

	my @new_catalog = @catalog;
	my $size_array = @new_catalog;

	for (my $i = 0; $i < $size_array; $i++){
	#Удаление книг с другими авторами
		if (lc( $new_catalog[$i]->{"Author"} ) ne lc($author)) { delete $new_catalog[$i]; }
	}
	return @new_catalog;
}

sub sort_for_date {
	my(@new_catalog) = @_;
	@new_catalog = sort { ( $b->{"Information"}->{"Published"} ) <=> ( $a->{"Information"}->{"Published"} ) } @new_catalog;
	return @new_catalog;
}

sub position_user {
	my($name_user) = @_;
	my @catalog_position_user;
	my @catalog_user_books; # Каталог для хранения книг определённого юзера

	open FILEWORK, "<", "users_position.json" or die "Ошибка открытия файла users_position.json: $!\n";
	$/ = undef;
	@catalog_position_user_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
	close FILEWORK;

	my $i = 0;
	while ( $catalog_position_user_json[0]->[$i] ) {
	$catalog_position_user[$i] = $catalog_position_user_json[0]->[$i];
	$i++;
	}

	my $size_array = @catalog_position_user;
	for (my $i = 0; $i < $size_array; $i++){
		if ( lc($catalog_position_user[$i]->{"User"}) eq lc($name_user) ) {
			my $books = $catalog_position_user[$i]->{"Books"};
			foreach my $book (@$books) {
				my $size_array = @catalog;
				for ( my $i = 0; $i < $size_array; $i++ ) {
					my $hash = $catalog[$i];
					while( my ( $key1, $value1) = each %$hash ) {
						if ( $key1 eq "ISBN" and $value1 eq $book) {
							push(@catalog_user_books, $catalog[$i]);
						}
					}
            	}
            }
        }
	}
	return @catalog_user_books;
}

sub save_position_user {
	my($name_user, $isbn) = @_;
	my @catalog_position_user; # Корзина с юзерами и их заказами

	open FILEWORK, "<", "users_position.json" or die "Ошибка открытия файла users_position.json: $!\n";
	$/ = undef;
	@catalog_position_user_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
	close FILEWORK;

	my $i = 0;
	while ( $catalog_position_user_json[0]->[$i] ) {
	$catalog_position_user[$i] = $catalog_position_user_json[0]->[$i];
	$i++;
	}

	my $size_array = @catalog_position_user;
	for (my $i = 0; $i < $size_array; $i++){
		if ( lc($catalog_position_user[$i]->{"User"}) eq lc($name_user) ) {
			foreach my $book ($catalog_position_user[$i]->{"Books"}) {
                
            }
		}
	}

	return 0;
}


1;