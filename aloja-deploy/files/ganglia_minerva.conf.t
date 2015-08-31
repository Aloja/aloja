udp_send_channel {
  host = minerva-101
  port = 8899
}


/* You can specify as many udp_recv_channels as you like as well. */
udp_recv_channel {
  port = 8899
}

/* You can specify as many tcp_accept_channels as you like to share
   an xml description of the state of the cluster */
tcp_accept_channel {
  port = 8899

  acl {
    default = "deny"

    access {
      ip = 127.0.0.1
      mask = 32
      action = "allow"
    }
  }
}

