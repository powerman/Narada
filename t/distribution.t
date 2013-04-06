use Test::More;

# work around to allow loading Narada::Log without config/log/*
use Narada::Config;
no warnings 'redefine';
sub Narada::Config::get_config_line :Export {
    $_[0] eq 'log/type'   ? 'file' :
    $_[0] eq 'log/output' ? '/dev/null' :
    $_[0] eq 'log/level'  ? 'DEBUG' : die;
};

eval 'require Test::Distribution';
plan( skip_all => 'Test::Distribution not installed' ) if $@;
Test::Distribution->import(
#    podcoveropts => {
#        also_private    => [
#            qr/^(?:IMPORT)$/,
#        ],
#        pod_from        => 'MAIN PM FILE HERE',
#    }
);
