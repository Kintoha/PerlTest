package NewBackend;
use JSON::XS;
use JSON;

require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(process_request);

my @catalog_json; # Каталог, заполняемый из файла catalog.json
my @catalog; # Структурированный каталог, получаемый из @catalog_json
my @catalog_position_user_json; # Каталог с пользователями и их заказами

open FILEWORK, "<", "catalog.json" or die "Ошибка открытия файла catalog.json: $!\n";
$/ = undef;
# Декодируем каталог из JSON файла
@catalog_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
close FILEWORK;

# Заполняем @catalog из @catalog_json чтобы избавиться от лишней вложенности
my $i = 0;
while ( $catalog_json[0]->[$i] ) {
	$catalog[$i] = $catalog_json[0]->[$i];
	$i++;
}

# Узнаём размер каталога
my $size_catalog = @catalog;

# Маршруты url, которые содержат имя функции,
# которую нужно выбрать в зависимости от выбранного маршрута.
# s_ это константы
# v_ это переменные
my @route_table = (
	["catalog", "s_catalog"],
	["sort_for_author", "s_catalog", "v_author"],
	["sort_for_author_and_date", "s_catalog", "v_author", "v_date"],
	["position_user", "s_orders", "v_name_user"],
	["save_position_user", "s_orders", "v_name_user", "s_new", "v_isbn"]
);

# Функция разбирает url, определяет маршрут и берёт из него имя нужной функции
sub process_request{
	my ($url) = @_;
	my $error;
	my $name_func_to_run;
	my @params_to_func;
	my @array_path = split /\//, $url;
	my $array_path_size = @array_path;
	
	my $route_table_size = @route_table;

	for (my $i = 0; $i < $route_table_size; $i++){
		$error = 0;
		@params_to_func = ();
		my $route_link = $route_table[$i];
		my @tmp_array = @$route_link;
		

		my $route_size = @tmp_array;

		if($route_size == $array_path_size){
			
			for (my $j = 1; $j < $route_size; $j++) {

				my $prefix = substr($tmp_array[$j], 0, 2);
				
				my $route_param = $tmp_array[$j];
				substr($route_param, 0, 2) = "";				

				if($prefix eq "s_"){
					if($route_param ne $array_path[$j]){
						$error = 1;
						last;
					}
				}
				else{
					push(@params_to_func, $array_path[$j]);
				}
			}

			if(!$error){
				$name_func_to_run = $tmp_array[0];
				last;
			}
		}
	}

	if (!$error) {
		run_fun($name_func_to_run, @params_to_func);
	}
	else{
		return 0;
	}
}

sub run_fun{
	my( $fun_name2, @params ) = @_;
	my $fun_name = \&{$fun_name2};
	&$fun_name(@params);
}

sub catalog {
	return @catalog;
}

sub sort_for_author {
	my ($author) = @_;

	my @new_catalog;
	for (my $i = 0; $i < $size_catalog; $i++){
		if ($catalog[$i]->{"Author"} eq $author) {
			# Заполняем массив @new_catalog только книгами выбранного автора
			push (@new_catalog, $catalog[$i]);
		}
	}
	return @new_catalog;
}

sub sort_for_date {
	my (@new_catalog) = @_;
	# Сортируем книги по дате публикации
	@new_catalog = sort { ( $b->{"Information"}->{"Published"} ) <=> ( $a->{"Information"}->{"Published"} ) } @new_catalog;
	return @new_catalog;
}

sub sort_for_author_and_date {
	my ($author) = @_;
	return sort_for_date( sort_for_author( $author ) );
}

sub position_user {
	my ($name_user) = @_;
	my @catalog_position_user;
	my @catalog_user_books; # Каталог для хранения книг определённого юзера

	open FILEWORK, "<", "users_position.json" or die "Ошибка открытия файла users_position.json: $!\n";
	$/ = undef;
	@catalog_position_user_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
	close FILEWORK;

	# Заполняем @catalog_position_user из @catalog_position_user_json чтобы избавиться от лишней вложенности
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
				for ( my $i = 0; $i < $size_array; $i++ ) {
					my $hash = $catalog[$i];
					while( my ( $key1, $value1) = each %$hash ) {
						if ( $key1 eq "ISBN" and $value1 eq $book) {
							# Заполняем @catalog_user_books книгам, которые заказал этот юзер
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
	my ($name_user, $isbn) = @_;
	my @catalog_position_user; # Корзина с юзерами и их заказами
	my $found_a_book = "nop";

	open FILEWORK, "<", "users_position.json" or die "Ошибка открытия файла users_position.json: $!\n";
	$/ = undef;
	@catalog_position_user_json = JSON::XS -> new -> utf8 -> decode(<FILEWORK>);
	close FILEWORK;

	# Заполняем @catalog_position_user из @catalog_position_user_json чтобы избавиться от лишней вложенности
	my $i = 0;
	while ( $catalog_position_user_json[0]->[$i] ) {
		$catalog_position_user[$i] = $catalog_position_user_json[0]->[$i];
		$i++;
	}

	my @array_isbns; # Массив всех ISBN в каталоге
	for ( my $i = 0; $i < $size_catalog; $i++ ) {
		my $hash = $catalog[$i];
		while( my ( $key1, $value1) = each %$hash ) {
			if ( $key1 eq "ISBN" ) {
				push(@array_isbns, $value1)
			}
		}
	}
	foreach my $isbn_from_the_array (@array_isbns) {
		# Если книга в каталоге с таким ISBN найдена, записываем во временную переменную значение yep
		if ($isbn_from_the_array eq $isbn) { $found_a_book = "yep"; }
	}
	# Если книг в каталоге с таким ISBN нет, функция возвращает nop
	if ($found_a_book eq "nop") { return "nop"; }



	for ( my $i = 0; $i < $size_catalog; $i++ ) {
	my $hash = $catalog[$i];
		while( my ( $key1, $value1) = each %$hash ) {
			if ( $key1 eq "ISBN" and $value1 eq $isbn) {
				if ($catalog[$i] -> {"new_order"} eq "nop")
				{
					$catalog[$i] -> {"new_order"} = "yep";

					my $size_array = @catalog_position_user;
					for (my $i = 0; $i < $size_array; $i++){
						if ( lc($catalog_position_user[$i]->{"User"}) eq lc($name_user) ) {
							# Добавляем новую книгу к заказам юзера
							push ($catalog_position_user[$i]->{"Books"}, $isbn);
						}
					}
				}
			}
		}
	}

# Перезаписываем каталог книг с новым значением new_order
my $new_catalog = JSON::XS->new->pretty(1)->utf8(1)->encode(\@catalog);
open( my $fh1, '+>', "catalog.json" ) or die "Не удалось открыть catalog.json - $!\n";
print $fh1 $new_catalog;
close $fh1;

# Перезаписываем каталог заказов пользователей, добавив в него новый заказ юзеру
my $new_catalog_position_user = JSON::XS->new->pretty(1)->utf8(1)->encode(\@catalog_position_user);
open( my $fh2, '+>', "users_position.json" ) or die "Не удалось открыть users_position.json - $!\n";
print $fh2 $new_catalog_position_user;
close $fh2;

return "yep";
}


1;