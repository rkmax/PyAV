from av.video.frame cimport VideoFrame


cdef class VideoPlane(Plane):
    
    def __cinit__(self, VideoFrame frame, int index):
        
        for i in range(frame.format.ptr.nb_components):
            if frame.format.ptr.comp[i].plane == index:
                self.component = frame.format.components[i]
                break
        else:
            raise RuntimeError('could not find plane %d of %r' % (index, frame.format))

        self.buffer_size = self.frame.ptr.linesize[self.index] * self.component.height

    property width:
        """Pixel width of this plane."""
        def __get__(self):
            return self.component.width

    property height:
        """Pixel height of this plane."""
        def __get__(self):
            return self.component.height
