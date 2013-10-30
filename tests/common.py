import errno
import os
from unittest import TestCase as _Base

import av
from av.frame import Frame
from av.packet import Packet
from av.stream import Stream
from av.utils import AVError


def _sandbox():
    sandbox = os.path.join(
        os.path.dirname(__file__),
        'sandbox',
        datetime.datetime.now().strftime('%Y%m%d-%H%M%S'),
    )
    if not os.path.exists(sandbox):
        os.makedirs(sandbox)
        last = os.path.join(os.path.dirname(__file__), 'sandbox', 'last')
        if os.path.exists(last):
            os.unlink(last)
        os.symlink(sandbox, last)


class TestCase(_Base):

    @classmethod
    def _sandbox(cls):
        path = os.path.join(_sandbox(), cls.__name__)
        try:
            os.makedirs(path)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise
        return path

    @property
    def sandbox(self):
        return self._sandbox()
