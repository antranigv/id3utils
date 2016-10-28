VOC = /opt/voc/bin/voc


ALL:
	$(VOC) -s id3.Mod catID3Tags.Mod -m

clean:
	rm *.c *.o *.h *.sym
