package BaselinerX::CA::Harvest::Project;
use Baseliner::Plug;
use Baseliner::Utils;
use Baseliner::Core::DBI;
extends 'BaselinerX::Type::Service';
no Moose;

use Try::Tiny;

register 'config.ca.harvest.replace' => {
    metadata => [
        { id=>'project', label=>'Harvest Project', },
    ]
};

register 'service.ca.harvest.replace_project' => {
    config => 'config.ca.harvest.replace' ,
    show_in_menu => 1,
    name => 'Sustituir [project] por grupos en Harvest',
    handler => sub {
        my ($self,$c,$config)=@_;
        my $project = $config->{project};
        $self->chgPermisosAplicaciones($project);
		$self->chgPermisosEstados($project);
		$self->chgPermisosProcesos($project);
		$self->chgDefaultPackage($project);
    },
};

register 'service.ca.harvest.replace_apl' => {
    config => 'config.ca.harvest.replace' ,
    show_in_menu => 1,
    name => 'Sustituir grupos por [project] en Harvest',
    handler => sub {
        my ($self,$c,$config)=@_;
        my $project = $config->{project};
		$self->chgPermisosAplicacionesTemplates($project);
		$self->chgPermisosEstadosTemplates($project);
		$self->chgPermisosProcesosTemplates($project);
    },
};

register 'namespace.harvest.application' => {
	name	=>_loc('Application'),
	root    => 'application',
    can_job => 0,
	handler => sub {
		my ($self, $c, $p) = @_;
		my $rs = Baseliner->model('Harvest::Harenvironment')->search({ envobjid=>{ '>', '0'}, envisactive=>'Y' });
        my %apps;
		while( my $r = $rs->next ) {
			my $env_short = get_apl_code($r->environmentname);
            $apps{ $env_short }{ $r->environmentname } = { data=>{ $r->get_columns } };
		}
		my @ns;
        foreach my $app ( keys %apps ) {
            push @ns, BaselinerX::CA::Harvest::Namespace::Application->new({
                ns      => 'application/' . $app,
                ns_name => $app,
				ns_type => _loc('Application'),
				ns_id   => $app,
				ns_data => $apps{ $app },
                provider=> 'namespace.harvest.application',
                related => [  ],
			});
        }
		return \@ns;
    }
};

register 'namespace.harvest.project' => {
	name	=>_loc('Harvest Projects'),
	root    => 'harvest.project',
    can_job => 0,
	handler => sub {
		my ($self, $c, $p) = @_;
		my $rs = Baseliner->model('Harvest::Harenvironment')->search({ envobjid=>{ '>', '0'}, envisactive=>'Y' });
		my @ns;
		while( my $r = $rs->next ) {
			( my $env_short = $r->environmentname )=~ s/\s/_/g;
            push @ns, BaselinerX::CA::Harvest::Namespace::Project->new({
                ns      => 'harvest.project/' . $env_short,
                ns_name => $env_short,
				ns_type => _loc('Harvest Project'),
				ns_id   => $r->envobjid,
				ns_data => { $r->get_columns },
                provider=> 'namespace.harvest.project',
                related => [  ],
			});
		}
		return \@ns;
	},
};

sub get_apl_code {
    my $env = shift;
    #TODO make the regex a CI
    if( $env =~ /^(.*?)[_|\s].*$/ ) {
        return wantarray ? ( lc($1),uc($1) ) : $1;
    } else {
        return wantarray ? ( lc($env),uc($env) ) : $env;
    }
}

sub getUserGroupId {
    my $grpname = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
    $db->value("SELECT MAX(g.usrgrpobjid) FROM HARUSERGROUP g WHERE TRIM(g.usergroupname) = TRIM('$grpname')");
}

## cambia los permisos de acceso a aplicaciones de [project][-XX] a CAM[-XX]
sub chgPermisosAplicaciones {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my $logtxt=();
	my %GRPID;
	try {
		my %ENVS = $db->hash( "SELECT e.envobjid||'-'||ug.usrgrpobjid,e.envobjid,trim(environmentname),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname) 
				FROM harenvironment e,harenvironmentaccess ea,harusergroup ug
				WHERE e.envobjid=ea.envobjid AND ug.usrgrpobjid=ea.usrgrpobjid 
				AND trim(envisactive)<>'T' AND ug.usergroupname LIKE '%[project]%' ORDER BY 2");
		foreach my $key (keys %ENVS) {
			my ($eid,$envname,$grpidOld,$grpname,$grpnameOld)=@{$ENVS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname =~ s/\[project\]/$CAM/g;
			$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname'\n";
			$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
			my $grpidNew = $GRPID{$grpname};
			if( $grpidNew ) {
				$db->do( "DELETE FROM harenvironmentaccess WHERE envobjid=$eid AND usrgrpobjid=$grpidNew");
				$db->do( "UPDATE harenvironmentaccess SET usrgrpobjid=$grpidNew,secureaccess='N',updateaccess='N',viewaccess='Y',executeaccess='Y' 
					WHERE envobjid=$eid AND usrgrpobjid=$grpidOld" or die "ERROR SQL($DBI::err): $DBI::errstr");
			}
		}
		$self->log->info("Cambio de permisos en aplicaciones terminado OK.",$logtxt) if($logtxt);
	} catch {
		$self->log->error("ERROR en cambio de permisos en aplicaciones.",$logtxt."\n".shift());
	};
	$db->commit;
}

## cambia los permisos de acceso a estados de [project][-XX] a CAM[-XX]
sub chgPermisosEstados {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my %GRPID;
	my $logtxt=();
	try {
		my %STAS = $db->hash( "SELECT s.stateobjid||'-'||ug.usrgrpobjid,e.envobjid,s.stateobjid,trim(environmentname),trim(statename),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname) 
				FROM HARENVIRONMENT e,HARSTATEACCESS sa,HARSTATE s,HARUSERGROUP ug
				WHERE e.envobjid=s.envobjid AND s.stateobjid=sa.stateobjid AND ug.usrgrpobjid=sa.usrgrpobjid 
				AND trim(envisactive)<>'T' 
				AND ug.usergroupname LIKE '%[project]%' ORDER BY 2");
		foreach my $key (keys %STAS) {
			my ($eid,$sid,$envname,$staname,$grpidOld,$grpname,$grpnameOld)=@{$STAS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname =~ s/\[project\]/$CAM/g;
			$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname:$staname'\n";
			$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
			my $grpidNew = $GRPID{$grpname};
			if( $grpidNew ) {
				$db->do( "DELETE FROM harstateaccess WHERE stateobjid=$sid AND usrgrpobjid=$grpidNew");
				$db->do( "UPDATE harstateaccess SET usrgrpobjid=$grpidNew,updateaccess='N',updatepkgaccess='Y' 
					WHERE stateobjid=$sid AND usrgrpobjid=$grpidOld" 
					or die "ERROR SQL($DBI::err): $DBI::errstr");
			}
		}
		$self->log->info("aplicaciones - Cambio de permisos en estados terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio de permisos en estados.",$logtxt."\n".shift());
	};
	$db->commit;
}

## cambia los permisos de acceso a procesos de estado de [project][-XX] a CAM[-XX]
sub chgPermisosProcesos {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my $logtxt=();
	my %GRPID;
	try {
		my %PROCS = $db->hash( "SELECT p.processobjid||'-'||ug.usrgrpobjid,e.envobjid,s.stateobjid,p.processobjid,trim(environmentname),
				trim(statename),trim(processname),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname), sp.executeaccess
				FROM HARENVIRONMENT e,HARSTATEPROCESSACCESS sp,HARSTATE s,HARSTATEPROCESS p,HARUSERGROUP ug
				WHERE e.envobjid=s.envobjid AND s.stateobjid=sp.stateobjid 
				AND s.envobjid=e.envobjid AND ug.usrgrpobjid=sp.usrgrpobjid 
				AND sp.processobjid=p.processobjid AND trim(envisactive)<>'T' 
				AND ug.usergroupname LIKE '%[project]%' ORDER BY 2");
		foreach my $key (keys %PROCS) {
			my ($eid,$sid,$pid,$envname,$staname,$procname,$grpidOld,$grpname,$grpnameOld,$exec)=@{$PROCS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname =~ s/\[project\]/$CAM/g;
			if( $exec eq "N" ) {
				$logtxt.="Borrando grupo '$grpnameOld' en '$envname:$staname:$procname'\n";
				$db->do( "DELETE FROM harstateprocessaccess WHERE processobjid=$pid AND usrgrpobjid=$grpidOld AND executeaccess='N'");
			}
			else {
				$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname:$staname:$procname'\n";
				$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
				my $grpidNew = $GRPID{$grpname};
				if( $grpidNew ) {
					$db->do( "DELETE FROM harstateprocessaccess WHERE processobjid=$pid AND usrgrpobjid=$grpidNew");
					$db->do( "UPDATE harstateprocessaccess SET usrgrpobjid=$grpidNew,executeaccess='Y' 
						WHERE processobjid=$pid AND usrgrpobjid=$grpidOld\n") 
						or die "ERROR SQL($DBI::err): $DBI::errstr";
				}
				else {
					$logtxt.="ERROR: Grupo '$grpname' no encontrado. ¿Se ha cargado el CAM '$CAM' desde LDAP/LDIF?\n";
				}
			}
		}
		$self->log->info("Cambio de permisos en procesos terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio de permisos en procesos.",$logtxt."\n".shift());
	};
	$db->commit;
}

## cambia el nombre por defecto de los paquetes con [project] a CAM
sub chgDefaultPackage {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my $logtxt=();
	try {
		## ahora cambio los nombres de paquete
		my %PAQS = $db->hash( "SELECT p.processobjid,e.envobjid,s.stateobjid,trim(environmentname),trim(statename),trim(p.processname),
				trim(cp.DEFAULTPKGFORMNAME),trim(cp.DEFAULTPKGFORMNAME)
				FROM HARENVIRONMENT e,HARSTATE s,HARSTATEPROCESS p,HARCRPKGPROC cp
				WHERE e.envobjid=s.envobjid
				AND s.stateobjid=p.stateobjid 
				AND cp.processobjid=p.processobjid 
				AND trim(envisactive)<>'T' 
				AND cp.DEFAULTPKGFORMNAME LIKE '%[project]%' ORDER BY 2");
		foreach my $pid (keys %PAQS) {
			my ($eid,$sid,$envname,$staname, $procname, $defpkgNew, $defpkgOld ) = @{$PAQS{$pid}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$defpkgNew =~ s/\[project\]/$CAM/g;
			$logtxt.="Actualizando nombre de paquete por defecto '$defpkgOld' a '$defpkgNew' en '$envname:$staname:$procname'\n";
			$defpkgNew =~ s/\'/\'\'/g;
			$db->do( "UPDATE HARCRPKGPROC SET DEFAULTPKGFORMNAME='$defpkgNew' WHERE processobjid=$pid ") 
				or die "ERROR SQL($DBI::err): $DBI::errstr";
		}		
		$self->log->info("Cambio de nombres de paquetes por defecto terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio nombres de paquetes por defecto .",$logtxt."\n".shift());
	};
	$db->commit;
}

##########################################################################################
## Funciones de cambio de plantillas. 
##   Se intentará renombrar los grupos actuales a [project][-XX]
##    si el nuevo nombre de grupo no existe 
##   (pe. de 'Desarrollo' a '[project]ollo') se borrará el grupo del permiso.
##

sub chgPermisosAplicacionesTemplates {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my $logtxt=();
	my %GRPID;
	try {
		my %ENVS = $db->hash( "SELECT e.envobjid||'-'||ug.usrgrpobjid,e.envobjid,trim(environmentname),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname)
				FROM HARENVIRONMENT e,HARENVIRONMENTACCESS ea,HARUSERGROUP ug
				WHERE e.envobjid=ea.envobjid AND ug.usrgrpobjid=ea.usrgrpobjid 
				AND trim(environmentname) LIKE '\\_%' ESCAPE '\\'
				AND trim(envisactive)='T' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'PUBLIC%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'ADMINIST%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'RPT-%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'SCM%' 
				AND NOT trim(ug.usergroupname) LIKE '%[project]%' 
				ORDER BY 2");
		foreach my $key (keys %ENVS) {
			my ($eid,$envname,$grpidOld,$grpname,$grpnameOld)=@{$ENVS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname = "[project]".substr($grpname,3);
			$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname'\n";
			$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
			my $grpidNew = $GRPID{$grpname};
			if( $grpidNew ) {
				$db->do( "DELETE FROM harenvironmentaccess WHERE envobjid=$eid AND usrgrpobjid=$grpidNew\n");
				$db->do( "UPDATE harenvironmentaccess SET usrgrpobjid=$grpidNew,secureaccess='N',updateaccess='N',viewaccess='Y',executeaccess='Y' 
					WHERE envobjid=$eid AND usrgrpobjid=$grpidOld\n" or die "ERROR SQL($DBI::err): $DBI::errstr");
			}
			else {
				$logtxt.="Grupo '$grpname' inexistente. Borrado.\n";
				$db->do( "DELETE FROM harenvironmentaccess WHERE envobjid=$eid AND usrgrpobjid=$grpidOld\n");
			}
		}
		$self->log->info("Cambio de permisos en aplicaciones de plantillas terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio de permisos en plantillas.",$logtxt."\n".shift());
	};
	$db->commit;
}

sub chgPermisosEstadosTemplates {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my %GRPID;
	my $logtxt=();
	try {
		my %STAS = $db->hash( "SELECT s.stateobjid||'-'||ug.usrgrpobjid,e.envobjid,s.stateobjid,trim(environmentname),trim(statename),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname) 
				FROM HARENVIRONMENT e,HARSTATEACCESS sa,HARSTATE s,HARUSERGROUP ug
				WHERE e.envobjid=s.envobjid AND s.stateobjid=sa.stateobjid AND ug.usrgrpobjid=sa.usrgrpobjid 
				AND trim(environmentname) LIKE '\\_%' ESCAPE '\\'
				AND trim(envisactive)='T' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'PUBLIC%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'ADMINIST%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'RPT-%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'SCM%' 
				AND NOT trim(ug.usergroupname) LIKE '%[project]%' 
				ORDER BY 2");
		foreach my $key (keys %STAS) {
			my ($eid,$sid,$envname,$staname,$grpidOld,$grpname,$grpnameOld)=@{$STAS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname = "[project]".substr($grpname,3);
			$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname:$staname'\n";
			$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
			my $grpidNew = $GRPID{$grpname};
			if( $grpidNew ) {
				$db->do( "DELETE FROM harstateaccess WHERE stateobjid=$sid AND usrgrpobjid=$grpidNew\n");
				$db->do( "UPDATE harstateaccess SET usrgrpobjid=$grpidNew,updateaccess='N',updatepkgaccess='Y' 
					WHERE stateobjid=$sid AND usrgrpobjid=$grpidOld\n") 
					or die "ERROR SQL($DBI::err): $DBI::errstr";
			}
			else {
				$logtxt.="Grupo '$grpname' inexistente. Borrado.\n";
				$db->do( "DELETE FROM harstateaccess WHERE stateobjid=$sid AND usrgrpobjid=$grpidOld\n");
			}
		}
		$self->log->info("Cambio de permisos en estados de plantillas terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio de permisos en estados de plantillas.",$logtxt."\n".shift());
	};
	$db->commit;
}

sub chgPermisosProcesosTemplates {
    my $self = shift;
    my $apl = shift;
    my $db = new Baseliner::Core::DBI({ model=>'Harvest' });
	my $logtxt=();
	my %GRPID;
	try {
		##antes de empezar, borro los permisos de procesos que estén a executeaccess='N' en plantillas y projects
		$db->do( "DELETE FROM HARSTATEPROCESSACCESS sp 
				WHERE trim(sp.executeaccess)='N'
				AND EXISTS ( SELECT * FROM HARENVIRONMENT e,HARSTATE s 
				   	 WHERE e.envobjid=s.envobjid AND sp.stateobjid=s.stateobjid )");
		##proceso los permisos que no son [project]...		   	 
		my %PROCS = $db->hash( "SELECT p.processobjid||'-'||ug.usrgrpobjid,e.envobjid,s.stateobjid,p.processobjid,trim(environmentname),trim(statename),trim(processname),ug.usrgrpobjid,trim(ug.usergroupname),trim(ug.usergroupname)
				FROM HARENVIRONMENT e,HARSTATEPROCESSACCESS sp,HARSTATE s,HARSTATEPROCESS p,HARUSERGROUP ug
				WHERE e.envobjid=s.envobjid AND s.stateobjid=sp.stateobjid 
				AND s.envobjid=e.envobjid AND ug.usrgrpobjid=sp.usrgrpobjid AND sp.processobjid=p.processobjid 
				AND trim(environmentname) LIKE '\\_%' ESCAPE '\\'
				AND trim(envisactive)='T' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'RPT-%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'PUBLIC%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'ADMINIST%' 
				AND NOT UPPER(trim(ug.usergroupname)) LIKE 'SCM%' 
				AND NOT trim(ug.usergroupname) LIKE '%[project]%' 
				ORDER BY 2");
		foreach my $key (keys %PROCS) {
			my ($eid,$sid,$pid,$envname,$staname,$procname,$grpidOld,$grpname,$grpnameOld)=@{$PROCS{$key}};
			my ($cam,$CAM)=get_apl_code($envname);
            next if( $apl && ($cam ne lc($apl)) );
			$grpname = "[project]".substr($grpname,3);
			$logtxt.="Actualizando grupo '$grpnameOld' a '$grpname' en '$envname:$staname:$procname'\n";
			$GRPID{$grpname}=getUserGroupId($grpname) unless $GRPID{$grpname};
			my $grpidNew = $GRPID{$grpname};
			if( $grpidNew ) {
				$db->do( "DELETE FROM harstateprocessaccess WHERE processobjid=$pid AND usrgrpobjid=$grpidNew\n");
				$db->do( "UPDATE harstateprocessaccess SET usrgrpobjid=$grpidNew,executeaccess='Y') 
					WHERE processobjid=$pid AND usrgrpobjid=$grpidOld\n") 
					or die "ERROR SQL($DBI::err): $DBI::errstr";
			}
			else {
				$logtxt.="Grupo '$grpname' inexistente. Borrado.\n";
				$db->do( "DELETE FROM harstateprocessaccess WHERE processobjid=$pid AND usrgrpobjid=$grpidOld\n");
			}
		}
		$self->log->info("Cambio de permisos en procesos de plantillas terminado OK.",$logtxt) if($logtxt );
	} catch {
		$self->log->error("ERROR en cambio de permisos en procesos de plantillas.",$logtxt."\n".shift());
	};
	$db->commit;
}

1;
