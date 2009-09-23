package BaselinerX::Job::Controller::Calendar;
use strict;
use base 'Catalyst::Controller';
use JavaScript::Dumper;
use Baseliner::Utils;

{
	package BaselinerX::Calendar::Window;
	use Moose;
	    has 'day' => ( is=>'rw', isa=>'Str' );
	    has 'id' => ( is=>'rw', isa=>'Str' );
	    has 'ns' => ( is=>'rw', isa=>'Str' );
	    has 'bl' => ( is=>'rw', isa=>'Str' );
	    has 'type' => ( is=>'rw', isa=>'Str' );
	    has 'start_time' => ( is=>'rw', isa=>'Str' );
	    has 'end_time' => ( is=>'rw', isa=>'Str' );
	    has 'active' => ( is=>'rw', isa=>'Str' );
	no Moose;
}

use Baseliner::Core::Baseline;
sub calendar_list_json : Path('/job/calendar_list_json')  {
    my ( $self, $c ) = @_;
	my $p = $c->request->parameters;
    my ($start, $limit, $query, $dir, $sort, $cnt ) = @{$p}{qw/start limit query dir sort/};
	my $rs = $c->model('Baseliner::BaliCalendar')->search(undef, { order_by => $sort ? "$sort $dir" : undef });
	my @rows;
	while( my $r = $rs->next ) {
        next if( $query && !query_array($query, $r->name, $r->description, $r->ns ));
        push @rows,
          {
            id          => $r->id,
            name        => $r->name,
            description => $r->description,
            bl          => Baseliner::Core::Baseline->name( $r->bl ),
            ns          => $r->ns,
            ns_desc     => $c->model('Namespaces')->find_text( $r->ns )
          } if( ($cnt++>=$start) && ( $limit ? scalar @rows < $limit : 1 ) );
    }
	$c->stash->{json} = { data => \@rows };		
	$c->forward('View::JSON');
}

sub calendar_list : Path('/job/calendar_list')  {
    my ( $self, $c ) = @_;
	$c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');
    $c->stash->{template} = '/comp/job_calendar_grid.mas';
}

#sub calendar_add : Path( '/job/calendar_add' ) {
	#my ( $self, $c ) = @_;
	#$c->stash->{template} = '/comp/job_calendar_comp.mas';
#}

sub calendar_update : Path( '/job/calendar_update' ) {
	my ( $self, $c ) = @_;
	my $p = $c->req->params;
	eval {
		if( $p->{action} eq 'create' ) {
			my $r1 = $c->model('Baseliner::BaliCalendar')->search({ ns=>$p->{ns}, bl => $p->{bl} });
			if( my $r = $r1->first ){
				die _loc("A calendar (%1) already exists for namespace %2 and baseline %3", $r->name, $p->{ns}, $p->{bl} );
			} else {
				my $row = $c->model('Baseliner::BaliCalendar')->create({
						name => $p->{name},
						description => $p->{description},
						ns => $p->{ns},
						bl => $p->{bl},
						});
			}
		} elsif( $p->{action} eq 'delete' ) {
			my $row = $c->model('Baseliner::BaliCalendar')->search({id=>$p->{id_cal}});
			$row->delete;
		} else {
			my $row = $c->model('Baseliner::BaliCalendar')->search({ id=>$p->{id_cal}})->first;
			$row->name( $p->{name} );
			$row->description( $p->{description} );
			$p->{ns} and $row->ns( $p->{ns} );
			$p->{bl} and $row->bl( $p->{bl} );
			$row->update;
		}
	};
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error modifying the calendar: ").$@  };
	} else { 
		$c->stash->{json} = { success => \1, msg => _loc("Calendar '%1' modified", $p->{name} ) };
	}
	$c->forward('View::JSON');	
}

sub calendar : Path( '/job/calendar' ) {
	my ( $self, $c ) = @_;
	my $id_cal = $c->stash->{id_cal} = $c->req->params->{id_cal};
	$c->forward('/namespace/load_namespaces');
	$c->forward('/baseline/load_baselines');
	# load the calendar row data
	$c->stash->{calendar} = $c->model('Baseliner::BaliCalendar')->search({ id => $id_cal })->first;
	$c->stash->{template} = '/comp/job_calendar_comp.mas';
}

sub calendar_show : Path( '/job/calendar_show' ) {
	my ( $self, $c ) = @_;
	my $id_cal = $c->stash->{id_cal} = $c->req->params->{id_cal};
	# get the panel id to be able to refresh it
	$c->stash->{panel} = $c->req->params->{panel};
	# load the calendar row data
	$c->stash->{calendar} = $c->model('Baseliner::BaliCalendar')->search({ id => $id_cal })->first;
	# prepare the html grid data
	$c->stash->{grid} = $c->forward( '/calendar/grid'); 
	$c->stash->{template} = '/comp/job_calendar.mas';
}

sub calendar_edit : Path( '/job/calendar_edit' ) {
	my ( $self, $c ) = @_;
	my $p = $c->req->params;
	$c->stash->{panel} = $p->{panel};
	my $id = $p->{id};
	my $id_cal = $p->{id_cal};
	my $win = $c->model('Baseliner::BaliCalendarWindow')->search({ id=>$id })->first;
	my $pdia = $p->{pdia};
	my $activa = 0;
	if (!$win && !$pdia ) {
		$c->stash->{not_found} = 1;
	} else {
		my $inicio;
		my $dia;
		my $fin;
		my $tipo;
		if( $pdia ) { # new window
			$c->stash->{create} = 1;
			$dia = substr($pdia, 4);
			$inicio=$p->{pini};
			$fin=$p->{pfin};
			$tipo="N";
		} else {  # existing window
			$inicio = $win->start_time;
			$fin = $win->end_time;
			$dia = $win->day;
			$tipo = $win->type;
			$activa = $win->active;
		}
		$c->stash->{id} = $id;
		$c->stash->{id_cal} = $id_cal;
		$c->stash->{dia} = $dia;
		$c->stash->{inicio} = $inicio;
		$c->stash->{fin} = $fin;
		$c->stash->{tipo} = $tipo;
		$c->stash->{activa} = $activa;
	}
	$c->stash->{template} = '/comp/job_calendar_edit.mas';
}

sub calendar_submit : Path('/job/calendar_submit') {
	my ( $self, $c ) = @_;
	my $p = $c->req->params;
	my $id_cal = $p->{id_cal};
	my $cierra = 0;
	my $id = $p->{id};
	my $cmd = $p->{cmd};
	my $ven_dia = $p->{ven_dia};
	my $ven_ini = $p->{ven_ini};
	my $ven_fin = $p->{ven_fin};
	my $ven_tipo= $p->{ven_tipo};

	eval {
		my @diaList;
		if( $ven_dia eq "L-V" ) {
			my @diaList=(0..4)
		} elsif( $ven_dia eq "L-D" ) {
			my @diaList=(0..6);
		} else {
			push @diaList, $ven_dia;
		}
		foreach my $ven_dia ( @diaList ) {
			if( $cmd eq "B" ) {
				#delete row
				if( $id ) {
					$c->model('Baseliner::BaliCalendarWindow')->search({ id=>$id })->first->delete;
					#stmt.executeUpdate("DELETE FROM distventanas WHERE id=" + id);
					$cierra=1;
				} else {
					die("<H5>Error: id '$id' de ventana no encontrado.</H5>"); 
				}
			}
			elsif( $cmd eq "A" ) {
				#InfVentana.Ventana ven=iv.getVentanaRec(ven_dia,ven_ini);
				my $ven = get_window( $id_cal, $ven_dia, $ven_ini );

				if( ref $ven && !($id eq $ven->{id}) && !("X" eq $ven->{tipo}) && !($ven_ini eq $ven->{fin}) ) {
					#Inicio está en una ventana ya existente
					die("<h5>Error: la hora de inicio de ventana ($ven_ini) se solapa con la siguiente ventana:<br>"
							. "<li>DIA=".$ven->{dia}. "<li>INICIO=".$ven->{start}
							."<li>FIN=". $ven->{fin} . "<li>TIPO=".$ven->{tipo} . " </h5>"); 
				} else {
					#ven=iv.getVentanaRec(ven_dia,ven_fin);
					$ven = get_window( $id_cal,$ven_dia, $ven_ini );

					if( $ven && !($id eq $ven->{id}) && !("X" eq $ven->{tipo}) && !($ven_fin eq $ven->{start}) ) { 
						#Fin está en una ventana ya existente
						die("<h5>Error: la hora de fin de ventana ($ven_fin) se solapa con la siguiente ventana: "
								. "<li>DIA=".$ven->{dia}. "<li>INICIO=".$ven->{start}
								."<li>FIN=". $ven->{fin} . "<li>TIPO=".$ven->{tipo} . " </h5>"); 
					} else {			
						unless( $id ) {  #new row
                            my $r =
                              $c->model('Baseliner::BaliCalendarWindow')->create(
                                {
									id_cal     => $id_cal,
                                    day        => $ven_dia,
                                    type       => $ven_tipo,
                                    start_time => $ven_ini,
                                    end_time   => $ven_fin
                                }
                              );
						} else {  #existing
							my $row = $c->model('Baseliner::BaliCalendarWindow')->search({ id=>$id })->first;
							$row->day( $ven_dia );
							$row->type( $ven_tipo );
							$row->start_time( $ven_ini );
							$row->end_time( $ven_fin );
							$row->update;
						}

						$c->forward( '/calendar/colindantes' );
						$cierra=1;
					}
				}
			} elsif( $cmd eq "C1" || $cmd eq "C0" ) {
				#Activar
				my $row = $c->model('Baseliner::BaliCalendarWindow')->search({ id=>$id })->first;
				$row->active( substr($cmd,1) );
				$row->update;
				$cierra=1;
			} else {
				die("<h5>Error: Comando desconocido o incompleto.</h5>");
			}

			last unless( $cierra )
		}
	};
	if( $@ ) {
        warn $@;
		$c->stash->{json} = { success => \0, msg => _loc("Error modifying the calendar: ").$@ };
	} else {
		$c->stash->{json} = { success => \1, msg => _loc("Calendar modified.") };
	}
	$c->forward('View::JSON');	
}

=head2 calendar_range

From a list of ns, finds all applicable ranges. 

If bl is supplied, the bl calendar has preference over all other calendars. For example:

    - /, *                      <== least precedence
    - /, DES
    - /apl/APL_ABC, *
    - /apl/APL_ABC, DES
    - /package/P1102121, *
    - /package/P1102121, DES    <== most precendence

=cut
#TODO needs to include specific date ranges as priority 
use Baseliner::Core::Namespace;
sub calendar_range : Private {
	my ($self,$c )=@_;
    my $day = $c->stash->{day};
    my @ns = @{ $c->stash->{ns} || [] };
    use YAML;
    my @range;
    #warn "CAL----VOY: ". Dump \@ns;
    my $date = parse_date('dd/mm/Y', $day);
    my $week_day = $date->day_of_week() - 1;
    for my $ns ( $c->model('Namespaces')->sort_ns({ asc=>1 }, @ns ) ) {
        my $ns_desc = $c->model('Namespaces')->find_text( $ns );
        for my $bl (  $c->stash->{bl}? ( '*', $c->stash->{bl} ) : '*' ) {
            my $bl_desc = Baseliner::Core::Baseline->name( $bl );
            #warn "CAL===>BL=$bl, NS=$ns ";
            my $rs = $c->model('Baseliner::BaliCalendar')->search({ ns=>$ns, bl=>$bl });
            while( my $r = $rs->next ) {
                #warn "CALENDAR===========>" . $r->name . " day=$day, $date=$date, week_day=$week_day";
                my $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$r->id, day=>$week_day });
                while( my $r2 = $rs2->next ) {
                    #warn "====> NS=" . $r->ns ;
                    #warn "NS=" . $r->ns . ", DATA=" . Dump $r2->get_columns;
                    if( $r2->active ) {
                        # last range has the most precedence
                        @range = range_add( \@range, "$ns_desc ($bl_desc)", $r2->start_time, $r2->end_time, $r2->type );
                        #push @range, { start=>$r2->start_time, end=>$r2->end_time, };
                    }
                }
            }
        }
    }
    $c->stash->{calendar_range} = \@range;
    $c->stash->{calendar_range_expand} = [ range_expand($date, @range) ];
}

=head2 range_add

Adds a new range into its place. 

=cut
sub range_add {
    my ($r, $name, $start, $end, $type ) = @_;
    my @range ;
    my $found;
    for my $r ( @{ $r || [] } ) {
        my @new_range = range_in($r->{name}, $r->{start},$r->{end}, $r->{type},$name,$start,$end,$type);
        if( @new_range ) {
            $found=1;
            push @range, @new_range;
        } else {
            push @range, $r;
        }
    }
    unless( $found ) {
        push @range, { name=>$name, start=>$start, end=>$end, type=>$type };
    } 
    return @range;
}

=head2 range_in

The second range (more specific) has priority over the first range. 

One type has no precedence over another. If types are the same, ranges are merged. Else, ranges are split case by case..

=cut
sub range_in {
    my ($n1,$s1,$e1,$t1,$n2,$s2,$e2,$t2) = map { s/://; $_ } @_;
    my @ret;
    #warn "================CHEQUEO RANGO: $s1,$e1,$s2,$e2";
    return if( ( $s1<$s2 ) && ( $e1<$s2 ) );
    return if( ( $s1>$e2 ) && ( $e1>$e2 ) );
    if( $t1 eq $t2 ) {  ## types match, merge ranges
        push @ret, { name=>$n2, start=>( $s1 < $s2 ? $s1 : $s2 ), end=>( $e1 > $e2 ? $e1 : $e2 ), type=>$t1 };
    } else { ## types are different, split ranges
        if ( ($s1 < $s2) && ($e1 < $e2) ) {  ##  s1 s2 e1 e2
            push @ret, { name=>$n1, start=>$s1, end=>$s2, type=>$t1 };
            push @ret, { name=>$n2, start=>$s2, end=>$e2, type=>$t2 };
        }
        elsif ( ($s1 > $s2) && ($e1 > $e2) ) {  ##  s2 s1 e2 e1
            push @ret, { name=>$n1, start=>$e2, end=>$e1, type=>$t1 };
            push @ret, { name=>$n2, start=>$s2, end=>$e2, type=>$t2 };
        }
        elsif ( ($s1 > $s2) && ($e1 < $e2) ) {  ##  s1 s2 e2 e1
            push @ret, { name=>$n2, start=>$s2, end=>$e2, type=>$t2 };
        }
        elsif ( ($s1 < $s2) && ($e1 > $e2) ) {  ##  s1 s2 e2 e1
            push @ret, { name=>$n1, start=>$s1, end=>$s2, type=>$t1 };
            push @ret, { name=>$n2, start=>$s2, end=>$e2, type=>$t2 };
            push @ret, { name=>$n1, start=>$e2, end=>$e1, type=>$t1 };
        }
    }
    #warn "=============SALIDA: " . Dump \@ret;
    return @ret;
}

sub to_num {  ( my $n = shift )=~ s/://g; return $n }

sub range_get {
    my ($time, @range) = @_;
    for my $r ( @range ) {
        return $r 
            if( to_num($time) >= to_num($r->{start}) && to_num($time)< to_num($r->{end}) );
    }
}
use DateTime;
sub range_expand {
    my $date = shift;
    my @range = @_;
    my @ret;
    my $inc = 1; # minute increment  TODO put this in inf
    my $today = DateTime->today(time_zone=>_tz);
    my $is_today = DateTime->compare( $date->truncate( to=>'day') , $today ); # zero means it's today
    my $now = DateTime->now(time_zone=>_tz);
    $now->subtract( minutes=>1 );  ## so it starts immediately
    #warn "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TODAY=$is_today ,".$date->truncate( to=>'day').",".DateTime->today;
    foreach my $hh ( 0..23 ) {
        for(my $mm=0; $mm<60; $mm+=$inc) {
            my $dt = new DateTime( time_zone=>_tz, hour=>$hh, minute=>$mm, year=>$date->year, month=>$date->month, day=>$date->day );
            #warn "!!!!! NOW=$now, DT=$dt";
            next if( $is_today==0 && DateTime->compare( $now, $dt ) > 0 ) ;
            #warn "#####   OK";
            # check if it's in range
            my $time = sprintf("%02d:%02d", $hh, $mm);
            my $range = range_get( $time, @range );  
            if( ref $range ) {
                push @ret, { 'time'=>$time, name=>$range->{name}, full_name=>"$time ($range->{type})", type=>$range->{type}, available=>1 };
            } else {
                # just ignore closed ranges for now
                #push @ret, { 'time'=>$time, name=>_loc('Closed'), type=>'C', available=>0 };
            }
        }
    }
    return @ret;
}

=head2 grid

Calculates the HTML calendar weekly grid.

=cut
sub grid : Private {
	my ($self,$c)=@_;
	my $id_cal = $c->stash->{id_cal};
	my $grid = {};
	my $lastctipo = ''; my $ctipo = '';
	my $lastid=-1;
	my $active = my $lastactive = my $ktipos = my $rowspan = 0;
	foreach my $dd ( 0..6 ) {
		my $row = 0;
		my $rowspan=0;
		my  $lastHora="00:00";
		my $hora="";
		foreach my $hh ( 0..23 ) {
			for(my $mm=0; $mm<60; $mm+=30) {
				last if( $hh>=24 && $mm>0 );
				$hora = sprintf("%02d:%02d", $hh, $mm);
				my $ven = get_window($id_cal,$dd, $hora );
				my $id = -1;
				$ctipo='X';
				$active=0;
				if($ven) {  
					$ctipo = $ven->{type};
					$id = $ven->{id};
					$active = $ven->{active};
				}
				if( $lastctipo ne $ctipo ) {
					if( $ktipos!=0 ) {
						my $clase = ($lastctipo eq 'N'?"normal":($lastctipo eq 'U'?"urgente":"nopase"));
						$clase .= $lastactive?"":"Des";
						my $data = { day=>$dd, id=>$lastid, class=>$clase, rowspan=>$rowspan, type=>$lastctipo, lasthour=>$lastHora, hour=>$hora };
						my $rowfinal = $row-$rowspan;
						$grid->{$dd}->{ $rowfinal } = $data;
						$rowspan=0;
					}
					$lastctipo=$ctipo;
					$lastid=$id;
					$lastactive=$active;
					$lastHora=$hora; 
					$ktipos++;
				}
				$rowspan++; #cuenta cuantas filas han pasado, para el rowspan
					$row++;
			}
		}
		unless( $lastHora eq "24:00" ) {
			my $clase = ($lastctipo eq 'N' ? "normal":($lastctipo eq 'U'?"urgente":"nopase"));
			$clase .= $lastactive?'':'Des';
			my $data = { day=>$dd, id=>$lastid, class=>$clase, rowspan=>$rowspan, type=>$lastctipo, lasthour=>$lastHora, hour=>"24:00" };
			my $rowfinal = $row-$rowspan;
			$grid->{$dd}->{ $rowfinal } = $data;
		}
	} #"
	return $grid;
}

sub get_window {
	my ($id_cal, $day, $hour)=@_;
	my $rs = Baseliner->model('Baseliner::BaliCalendarWindow')->search({ id_cal=>$id_cal, day=>$day });
	while( my $win = $rs->next ) {
		if( inside_window($win->start_time,$win->end_time,$hour) ) {
			return {  
				type=> $win->type,
				active=> $win->active,
				id=> $win->id,
				day=> $win->day,
				start_time=> $win->start_time,
				end_time=> $win->end_time,
			}
		}
	}
	return ;
}

sub colindantes : Private {
	my ($self,$c)=@_;
	# check for windows touching my bottom
	my $rs = $c->model('Baseliner::BaliCalendarWindow')->search(undef);
	while( my $row = $rs->next )  {
		#my $rs2 = $c->model('balicalendar')->search({ -or => { end_time=>$row->start_time, start_time=>$row->end_time }, type=>$row->type, day=>$row->day });
		my $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search({ start_time=>$row->end_time, type=>$row->type, day=>$row->day });
		while( my $row2 = $rs2->next ) {
			$row->end_time( $row2->end_time );
			$row->update;
			$row2->delete;
		}
	}
	# check for windows touching my head
	my $rs2 = $c->model('Baseliner::BaliCalendarWindow')->search(undef);
	while( my $row = $rs2->next )  {
		my $rs3 = $c->model('Baseliner::BaliCalendarWindow')->search({ end_time=>$row->start_time, type=>$row->type, day=>$row->day });
		while( my $row3 = $rs3->next ) {
			$row->start_time( $row3->start_time );
			$row->update;
			$row3->delete;
		}
	}
}

sub hour_to_num {
	$_=~ s/://g for( @_ );
}

sub inside_window {
	my ($start,$end,$hour)=@_;
	hour_to_num( $start, $end, $hour );
	if( $start && $end && $hour ) {
		return ( $hour>=$start && $hour<$end );
	} else {
		return 0;
	}
}

1;
