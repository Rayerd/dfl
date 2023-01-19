dub clean
dir examples | % { cd $_ && del ./bin/* && dub clean }
