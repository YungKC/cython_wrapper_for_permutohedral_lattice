import numpy as np
from cimage cimport Image
from cpermutohedrallattice cimport PermutohedralLattice
from cmodified_permutohedral cimport ModifiedPermutohedral
from myimage cimport pyImage

cdef class p:
    @staticmethod
    cdef _filter(float[:,:,:,::1] a, float[:,:,:,::1] b):
        a_pyImage = pyImage().set_data(a)
        b_pyImage = pyImage().set_data(b)
        r = PermutohedralLattice.filter(pyImage.get_img(a_pyImage),pyImage.get_img(b_pyImage))
        r_pyImage = pyImage().set_img(r)
        ret_tmp = np.asarray(r_pyImage)
        ret_tmp = np.copy(ret_tmp,order="C")
        a_pyImage.mydel()
        b_pyImage.mydel()
        return ret_tmp

    @staticmethod
    cdef _filter_with_mask(float[:,:,:,::1] a, float[:,:,:,::1] b, int[:,:,::1]mask, int mask_num):
        c_a = a.shape[3]
        c_b = b.shape[3]
        ret = np.zeros([1,a.shape[1],a.shape[2],a.shape[3]],dtype=np.float32)
        new_a = np.array(a)
        new_b = np.array(b)
        for i in range(mask_num):
            index = np.equal(mask,i)
            if np.sum(index) <= 0: continue
            new_a_ = np.reshape(new_a[index],(1,1,-1,c_a))
            new_b_ = np.reshape(new_b[index],(1,1,-1,c_b))
            ret_tmp = p._filter(new_a_,new_b_)
            ret[index] = np.reshape(ret_tmp,(-1,c_a))
        return ret

    @staticmethod
    cdef _filter_without_normalization(float[:,:,:,::1] a, float[:,:,:,::1] b):
        b_a = a.shape[0] # batch_size must be 1
        h_a = a.shape[1]
        w_a = a.shape[2]
        c_a = a.shape[3]
        c_b = b.shape[3]

        cdef ModifiedPermutohedral l
        l.init(&b[0,0,0,0],c_b,h_a*w_a)
        
        cdef float[::1] data = np.zeros([b_a*h_a*w_a*c_a],np.float32)
        l.compute(c_a,&data[0],&a[0,0,0,0])

        d = np.copy(data,order="C")
        return d.reshape([b_a,h_a,w_a,c_a])
        #return data

    @staticmethod
    def filter_without_normalization(float[:,:,:,::1] a ,float[:,:,:,::1] b):
        # a: the matric needs to be filered which shape is [batch_size,:,:,:]. b: the feature matric, which shape is [batch_size,:,:,:]
        batch_size = a.shape[0]
        h = a.shape[1]
        w = a.shape[2]
        c_a = a.shape[3]
        c_b = b.shape[3]
        ret = None
        for i in range(batch_size):
            if b.shape[0] == batch_size:
                j = i
            else:
                j = 0
            ret_tmp = p._filter_without_normalization(np.reshape(a[i,:,:,:],(1,h,w,c_a)),np.reshape(b[j,:,:,:],(1,h,w,c_b)))
            if ret is None:
                ret = ret_tmp
            else:
                ret = np.concatenate([ret,ret_tmp],axis=0)
        return ret

    @staticmethod
    def filter(float[:,:,:,::1] a ,float[:,:,:,::1] b):
        # a: the matric needs to be filered which shape is [batch_size,:,:,:]. b: the feature matric, which shape is [batch_size,:,:,:]
        batch_size = a.shape[0]
        h = a.shape[1]
        w = a.shape[2]
        c_a = a.shape[3]
        c_b = b.shape[3]
        ret = None
        for i in range(batch_size):
            if b.shape[0] == batch_size:
                j = i
            else:
                j = 0
            ret_tmp = p._filter(np.reshape(a[i,:,:,:],(1,h,w,c_a)),np.reshape(b[j,:,:,:],(1,h,w,c_b)))
            if ret is None:
                ret = ret_tmp
            else:
                ret = np.concatenate([ret,ret_tmp],axis=0)
        return ret

    @staticmethod
    def filter_with_mask(float[:,:,:,::1] a ,float[:,:,:,::1] b,int[:,:,::1] mask, int[::1] mask_num):
        batch_size = a.shape[0]
        h = a.shape[1]
        w = a.shape[2]
        c_a = a.shape[3]
        c_b = b.shape[3]
        ret = None
        for i in range(batch_size):
            if b.shape[0] == batch_size:
                j = i
            else:
                j = 0
            ret_tmp = p._filter_with_mask(np.reshape(a[i,:,:,:],(1,h,w,c_a)),np.reshape(b[j,:,:,:],(1,h,w,c_b)),np.reshape(mask[j],(1,h,w)),mask_num[j])
            if ret is None:
                ret = ret_tmp
            else:
                ret = np.concatenate([ret,ret_tmp],axis=0)
        return ret

