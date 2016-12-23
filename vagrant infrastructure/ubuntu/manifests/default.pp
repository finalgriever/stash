include apt
#include mysql

$development = 'development'
$testing = 'testing'
$production = 'production'

$env = 'development'

# Begin Utilities

if $env == 'development' {
	package {'git':
		ensure 	=> installed,
		name 	=> 'git'
	}
	
	file {'.vimrc':
		ensure	=> file,
		path	=> '/home/vagrant/.vimrc',
		source	=> '/home/vagrant/synced/.vimrc'
	}
	
	file {'.screenrc':
		ensure	=> file,
		path	=> '/home/vagrant/.screenrc',
		source	=> '/home/vagrant/synced/.screenrc'
	}
	
	file {'sshconf':
		path => '/home/vagrant/.ssh',
		source => '/home/vagrant/synced/ssh',
		recurse => true,
		mode => '0700'
	}

	package {'screen':
		ensure 	=> installed,
		name 	=> 'screen'
	}
	
	package {'vim':
		ensure 	=> installed,
		name 	=> 'vim'
	}
	
	exec { 'vundle':
		command => '/usr/bin/git clone https://github.com/VundleVim/Vundle.vim.git /home/vagrant/.vim/bundle/Vundle.vim',
		require => [Package['git'], Package['vim'], File['sshconf']]
	}
}

# End Utilities

# Begin PHP Install

file { '/etc/environment':
	content => inline_template('LC_ALL=en_US.UTF-8')
}

package { 'language':
	name => 'language-pack-en-base',
	ensure => installed
}

exec { 'pondrej':
	command	=> '/usr/bin/add-apt-repository ppa:ondrej/php',
	require	=> [Package['language'], File['/etc/environment']]
}

package { 'addPython':
	name	=> 'python-software-properties',
	ensure	=> installed
}

exec { 'aptUpdate':
	command	=> '/usr/bin/apt-get -y update',
	require	=> [Exec['pondrej'],
				Package['addPython']]
}

package { 'addPhp':
	name	=> 'php5.6',
	ensure	=> installed,
	install_options => ['--allow-unauthenticated', '-f', '-y', '--force-yes'],
	require => Exec['aptUpdate']
}

package { 'addFpm':
	name	=> 'php5.6-fpm',
	ensure	=> installed,
	require => Package['addPhp'],
	install_options => ['--allow-unauthenticated', '-f', '-y', '--force-yes']
}

file {'php.ini':
	ensure	=> file,
	path	=> '/etc/php/5.6/fpm/php.ini',
	source	=> '/vagrant/stash/phpini',
	require	=> Package['addFpm']
}

exec {'restartFpm':
	command	=> '/usr/bin/service php5.6-fpm restart',
	require	=> File['php.ini']
}

exec {'addComposer':
	command => '/usr/bin/curl -sS https://getcomposer.org/installer | sudo /usr/bin/php -- --install-dir=/usr/local/bin --filename=composer',
	require => Package['addPhp']
}

# End Php Install

# Begin Angular2 Install

exec {'nodePpa':
	command => '/usr/bin/curl -sL https://deb.nodesource.com/setup_6.x | /bin/bash -'
}

package {'nodejs':
	ensure 	=> installed,
	name 	=> 'nodejs',
	require => Exec['nodePpa']
}

#package {'npm':
#	ensure 	=> installed,
#	name 	=> 'npm',
#	require => Package['nodejs']
#}

exec {'upgradeNpm':
	command => '/usr/bin/npm install npm -g',
	require => Package['nodejs']
}

#exec {'upgradeNpm2':
#	command => '/usr/local/bin/npm install npm -g',
#	require => Exec['upgradeNpm1']
#}

# End Angular2 Install

# Begin Web Server Configuration

file { [  '/srv/', '/srv/web' ]:
	ensure => 'directory',
}

package {'nginx':
	ensure 	=> installed,
	name 	=> 'nginx'
}

package {'apache2':
	ensure	=> purged,
	name	=> 'apache2'
}

package {'apache2-bin':
	ensure	=> purged,
	name	=> 'apache2-bin'
}

package {'apache2-data':
	ensure	=> purged,
	name	=> 'apache2-data'
}

$siteConfFile = $env ? {
	'development' 	=> '/vagrant/stash/nginxdevsite',
	'testing'		=> '/vagrant/stash/nginxtestsite',
	'production'	=> '/vagrant/stash/nginxprodsite',
}

$nginxConfFile = $env ? {
	'development' 	=> '/vagrant/stash/nginxdevconf',
	'testing'		=> '/vagrant/stash/nginxtestconf',
	'production'	=> '/vagrant/stash/nginxprodconf',
}

file {'defaultconf':
	ensure	=> file,
	path	=> '/etc/nginx/sites-enabled/default',
	source 	=> $siteConfFile,
	require	=> Package['nginx']
}

exec {'nginxStop':
	command	=> '/usr/sbin/nginx -s stop',
	require	=> File['defaultconf']
}

exec {'nginxStart':
	command	=> '/usr/sbin/nginx',
	require	=> Exec['nginxStop']
}

# End Web Server Configuration

# Begin SQL Server Configuration

class { '::mysql::server':
	root_password 		=> 'password',
	override_options	=> { 'mysqld' => { 'max_connections' => '1024' } }
}

# End SQL Server Configuration