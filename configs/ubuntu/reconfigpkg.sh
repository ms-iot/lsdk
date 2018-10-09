# reconfigure default setting of some application packages

# for sshd
if [ -f /etc/ssh/sshd_config ]; then
    sed -i "s/PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config
fi

# for tftp service
if dpkg-query -W tftp-hpa 1>/dev/null 2>&1 ; then
    chmod 777 /var/lib/tftpboot
    cat > /etc/init.d/tftp <<EOF
    service tftp
    {
       disable = no
       socket_type = dgram
       protocol = udp
       wait = yes
       user = root
       server = /usr/sbin/in.tftpd
       server_args = -s /var/lib/tftpboot -c
       per_source = 11
       cps = 100 2
    }
EOF
    sed -i '/TFTP_OPTIONS/d' /etc/default/tftpd-hpa
    sed -i '/TFTP_ADDRESS/aTFTP_OPTIONS=" -l -c -s"' /etc/default/tftpd-hpa
fi
