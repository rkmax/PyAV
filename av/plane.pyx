from libc.string cimport memcpy
from cpython cimport PyString_FromStringAndSize

cdef class Plane(object):
    
    def __cinit__(self, Frame frame, int index):
        self.frame = frame
        self.index = index
        self.buffer_size = frame.ptr.linesize[index]

    def __repr__(self):
        return '<av.%s at 0x%x>' % (self.__class__.__name__, id(self))
    
    property line_size:
        """Bytes per horizontal line in this plane."""
        def __get__(self):
            return self.frame.ptr.linesize[self.index]

    def to_bytes(self):
        return PyString_FromStringAndSize(<char*>self.frame.ptr.extended_data[self.index], self.buffer_size)

    def update_from_string(self, bytes input):
        """Replace the data in this plane with the given string."""
        if len(input) != self.buffer_size:
            raise ValueError('got %d bytes; need %d bytes' % (len(input), self.buffer_size))
        memcpy(<void*>self.frame.ptr.extended_data[self.index], <void*><char*>input, self.buffer_size)

    # Legacy buffer support. For `buffer` and PIL.
    # See: http://docs.python.org/2/c-api/typeobj.html#PyBufferProcs

    def __getsegcount__(self, Py_ssize_t *len_out):
        if len_out != NULL:
            len_out[0] = <Py_ssize_t>self.buffer_size
        return 1

    def __getreadbuffer__(self, Py_ssize_t index, void **data):
        if index:
            raise RuntimeError("accessing non-existent buffer segment")
        data[0] = <void*>self.frame.ptr.extended_data[self.index]
        return <Py_ssize_t>self.buffer_size

    def __getwritebuffer__(self, Py_ssize_t index, void **data):
        if index:
            raise RuntimeError("accessing non-existent buffer segment")
        data[0] = <void*>self.frame.ptr.extended_data[self.index]
        return <Py_ssize_t>self.buffer_size

    # PEP 3118 buffers. For `memoryviews`.
    # We cannot supply __releasebuffer__ or PIL will no longer think it can
    # take a read-only buffer. How silly.

    def __getbuffer__(self, Py_buffer *view, int flags):

        view.buf = <void*>self.frame.ptr.extended_data[self.index]
        view.len = <Py_ssize_t>self.buffer_size
        view.readonly = 0
        view.format = NULL
        view.ndim = 1
        view.itemsize = 1

        # We must hold onto these arrays, and share them amoung all buffers.
        # Please treat a Frame as immutable, okay?
        self._buffer_shape[0] = self.buffer_size
        view.shape = &self._buffer_shape[0]
        self._buffer_strides[0] = view.itemsize
        view.strides = &self._buffer_strides[0]
        self._buffer_suboffsets[0] = -1
        view.suboffsets = &self._buffer_suboffsets[0]
