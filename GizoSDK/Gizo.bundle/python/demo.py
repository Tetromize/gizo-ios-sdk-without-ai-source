#import coremltools as ct
import numpy as np
import time

from roi import GetROI

groi = GetROI((160,320))

#from PIL import Image

class SimplifiedCamConversion:
    def __init__(self, cc_cfg):
        # find the corresponding dst corner points in the src
        j1_dst2src = cc_cfg["K_src"][1, 2] + cc_cfg["K_src"][1, 1] * (1 - cc_cfg["K_dst"][1, 2]) / cc_cfg["K_dst"][1, 1]    # 1-based index
        j2_dst2src = cc_cfg["K_src"][1, 2] + cc_cfg["K_src"][1, 1] * (cc_cfg["imsize_dst"][0] - cc_cfg["K_dst"][1, 2]) / cc_cfg["K_dst"][1, 1]
        i1_dst2src = cc_cfg["K_src"][0, 2] + cc_cfg["K_src"][0, 0] * (1 - cc_cfg["K_dst"][0, 2]) / cc_cfg["K_dst"][0, 0]
        i2_dst2src = cc_cfg["K_src"][0, 2] + cc_cfg["K_src"][0, 0] * (cc_cfg["imsize_dst"][1] - cc_cfg["K_dst"][0, 2]) / cc_cfg["K_dst"][0, 0]
        # handle outbound coordinates
        j1_dst2src = 1 if j1_dst2src < 1 else j1_dst2src
        j2_dst2src = cc_cfg["imsize_src"][0] if j2_dst2src > cc_cfg["imsize_src"][0] else j2_dst2src
        i1_dst2src = 1 if i1_dst2src < 1 else i1_dst2src
        i2_dst2src = cc_cfg["imsize_src"][1] if i2_dst2src > cc_cfg["imsize_src"][1] else i2_dst2src
        # find the corresponding inbound corner points in the dst
        j1_src2dst = cc_cfg["K_dst"][1, 2] + cc_cfg["K_dst"][1, 1] * (j1_dst2src - cc_cfg["K_src"][1, 2]) / cc_cfg["K_src"][1, 1]    # 1-based index
        j2_src2dst = cc_cfg["K_dst"][1, 2] + cc_cfg["K_dst"][1, 1] * (j2_dst2src - cc_cfg["K_src"][1, 2]) / cc_cfg["K_src"][1, 1]
        i1_src2dst = cc_cfg["K_dst"][0, 2] + cc_cfg["K_dst"][0, 0] * (i1_dst2src - cc_cfg["K_src"][0, 2]) / cc_cfg["K_src"][0, 0]
        i2_src2dst = cc_cfg["K_dst"][0, 2] + cc_cfg["K_dst"][0, 0] * (i2_dst2src - cc_cfg["K_src"][0, 2]) / cc_cfg["K_src"][0, 0]
        # round and make 0-based index (src coordinates)
        j1_src2dst = int(round(j1_src2dst)) - 1
        j2_src2dst = int(round(j2_src2dst)) - 1
        i1_src2dst = int(round(i1_src2dst)) - 1
        i2_src2dst = int(round(i2_src2dst)) - 1
        # handle outbound coordinates in case of minor loss (just to be sure)
        j1_src2dst = 0 if j1_src2dst < 0 else j1_src2dst
        j2_src2dst = cc_cfg["imsize_dst"][0] - 1 if j2_src2dst > (cc_cfg["imsize_dst"][0] - 1) else j2_src2dst
        i1_src2dst = 0 if i1_src2dst < 0 else i1_src2dst
        i2_src2dst = cc_cfg["imsize_dst"][1] - 1 if i2_src2dst > (cc_cfg["imsize_dst"][1] - 1) else i2_src2dst
        # round and make 0-based index (dst coordinates)
        j1_dst2src = int(round(j1_dst2src)) - 1
        j2_dst2src = int(round(j2_dst2src)) - 1
        i1_dst2src = int(round(i1_dst2src)) - 1
        i2_dst2src = int(round(i2_dst2src)) - 1

        
        
        w_src2dst = i2_src2dst - i1_src2dst
        h_src2dst = j2_src2dst - j1_src2dst

        self.rect_src2dst = (j1_src2dst, i1_src2dst, j2_src2dst, i2_src2dst)
        self.rect_dst2src = (j1_dst2src, i1_dst2src, j2_dst2src, i2_dst2src)
        self.src2dst_size = (w_src2dst, h_src2dst)      # (width, height) of src in dst
        self.cc_cfg = cc_cfg
        # print(self.rect_dst2src)    # (j1, i1, j2, i2)
        # print(self.src2dst_size)    # (W, H)

    def roi_in_src(self, dst_size=(704, 352)):
        """
        converts the coordinates of the cropped region in the dst frame to that of the src frame

        inputs
        ------
        dst_size : tuple        size of the cropped region in the dst frame (W, H)

        return
        ------
        rect : tuple            coordinates of the cropped region in the src frame
        """
        w_roi_dst = dst_size[0] if (dst_size[0] <= self.src2dst_size[0]) else self.src2dst_size[0]
        h_roi_dst = dst_size[1] if (dst_size[1] <= self.src2dst_size[1]) else self.src2dst_size[1]
        w_roi_src = w_roi_dst * self.cc_cfg["K_src"][0, 0] / self.cc_cfg["K_dst"][0, 0]
        h_roi_src = h_roi_dst * self.cc_cfg["K_src"][1, 1] / self.cc_cfg["K_dst"][1, 1]
        i1_roi_src = int(round(self.cc_cfg["K_src"][0, 2] - w_roi_src / 2))
        i2_roi_src = int(round(self.cc_cfg["K_src"][0, 2] + w_roi_src / 2))
        j2_roi_src = int(self.rect_dst2src[2])
        j1_roi_src = int(j2_roi_src - round(h_roi_src))
        rect_roi_src = (j1_roi_src, i1_roi_src, j2_roi_src, i2_roi_src)
        return rect_roi_src

# anchors
anchor_grid = [[[[[[12., 16.]]],[[[19., 36.]]],[[[40., 28.]]]]],
               [[[[[ 36.,75.]]], [[[ 76.,55.]]],[[[ 72., 146.]]]]],
               [[[[[142., 110.]]], [[[192., 243.]]], [[[459., 401.]]]]]]

#
options = dict(
    roi_size=(352,704),
    online_eval=False,
    obj=dict(
        car=dict(height=1.6),
        cv=dict(height=2.7)
        )
)

# cam conversion config
cc_cfg = dict(
    K_src=np.array([[1.218400e+03, 0.000000e+00, 6.336272e+02],
                    [0.000000e+00, 1.224400e+03, 3.650863e+02],
                    [0.000000e+00, 0.000000e+00, 1.000000e+00]], dtype=np.float32),  # mi 11
    K_dst=np.array([[7.215377e+02, 0.000000e+00, 6.095593e+02],
                    [0.000000e+00, 7.215377e+02, 1.728540e+02],
                    [0.000000e+00, 0.000000e+00, 1.000000e+00]], dtype=np.float32),     # kitti rect
    imsize_src=(720, 1280),
    imsize_dst=(384, 1242),
)

def _make_grid(nx=20, ny=20):
    yv, xv = np.meshgrid(np.arange(ny), np.arange(nx), indexing='ij')
    return np.stack((xv, yv), 2).reshape((1, 1, ny, nx, 2))

def split_for_trace_model(pred = None, anchor_grid = None):
#    print(pred[0].shape)
    z = []
    st = [8,16,32]
    for i in range(3):
        bs, _, ny, nx = pred[i].shape
        y = pred[i].reshape(bs, 3, 85, ny, nx).transpose((0, 1, 3, 4, 2))
        # y = pred[i].sigmoid()   # add sigmoid to the code
        y = 1/(1 + np.exp(-y))      # add sigmoid to the code
        gr = _make_grid(nx, ny)
        y[..., 0:2] = (y[..., 0:2] * 2. - 0.5 + gr) * st[i]  # xy
        y[..., 2:4] = (y[..., 2:4] * 2) ** 2 * anchor_grid[i]  # wh
        z.append(y.reshape(bs, -1, 85))
    pred = np.concatenate(z, 1)
    return pred

def clip_coords(boxes, img_shape):
    # Clip bounding xyxy bounding boxes to image shape (height, width)
    boxes[:, 0].clip(0, img_shape[1])  # x1
    boxes[:, 1].clip(0, img_shape[0])  # y1
    boxes[:, 2].clip(0, img_shape[1])  # x2
    boxes[:, 3].clip(0, img_shape[0])  # y2
    return boxes

def scale_coords(img1_shape, coords, img0_shape, ratio_pad=None):
    # Rescale coords (xyxy) from img1_shape to img0_shape
    if ratio_pad is None:  # calculate from img0_shape
        gain = min(img1_shape[0] / img0_shape[0], img1_shape[1] / img0_shape[1])  # gain  = old / new
        pad = (img1_shape[1] - img0_shape[1] * gain) / 2, (img1_shape[0] - img0_shape[0] * gain) / 2  # wh padding
    else:
        gain = ratio_pad[0][0]
        pad = ratio_pad[1]

    coords[:, [0, 2]] -= pad[0]  # x padding
    coords[:, [1, 3]] -= pad[1]  # y padding
    coords[:, :4] /= gain
    coords = clip_coords(coords, img0_shape)
    return coords

def numpy_nms(boxes, scores, iou_threshold):
    idxs = scores.argsort()
    keep = []
    while idxs.size > 0:
        max_score_index = idxs[-1]
        max_score_box = boxes[max_score_index][None, :]
        keep.append(max_score_index)

        if idxs.size == 1:
            break
        idxs = idxs[:-1]
        other_boxes = boxes[idxs]  # [?, 4]
        ious = box_iou(max_score_box, other_boxes)
        idxs = idxs[ious[0] <= iou_threshold]

    keep = np.array(keep)
    return keep

def non_max_suppression(prediction, conf_thres=0.7, iou_thres=0.45, classes=None, agnostic=False, multi_label=False,
                        labels=()):
    """Runs Non-Maximum Suppression (NMS) on inference results

    Returns:
         list of detections, on (n,6) tensor per image [xyxy, conf, cls]
    """

    nc = prediction.shape[2] - 5  # number of classes
    xc = prediction[..., 4] > conf_thres  # candidates

    # Settings
    min_wh, max_wh = 2, 4096  # (pixels) minimum and maximum box width and height
    max_det = 300  # maximum number of detections per image
    max_nms = 30000  # maximum number of boxes into torchvision.ops.nms()
    time_limit = 10.0  # seconds to quit after
    redundant = True  # require redundant detections
    multi_label &= nc > 1  # multiple labels per box (adds 0.5ms/img)
    merge = False  # use merge-NMS

    t = time.time()
    output = [np.zeros((0, 6))] * prediction.shape[0]
    for xi, x in enumerate(prediction):  # image index, image inference
        # Apply constraints
        # x[((x[..., 2:4] < min_wh) | (x[..., 2:4] > max_wh)).any(1), 4] = 0  # width-height
        x = x[xc[xi]]  # confidence

        # Cat apriori labels if autolabelling
        if labels and len(labels[xi]):
            l = labels[xi]
            v = np.zeros((len(l), nc + 5))
            v[:, :4] = l[:, 1:5]  # box
            v[:, 4] = 1.0  # conf
            v[range(len(l)), l[:, 0].long() + 5] = 1.0  # cls
            x = np.concatenate((x, v), 0)

        # If none remain process next image
        if not x.shape[0]:
            continue

        # Compute conf
        x[:, 5:] *= x[:, 4:5]  # conf = obj_conf * cls_conf

        # Box (center x, center y, width, height) to (x1, y1, x2, y2)
        box = xywh2xyxy(x[:, :4])

        # Detections matrix nx6 (xyxy, conf, cls)
        if multi_label:
            i, j = (x[:, 5:] > conf_thres).nonzero(as_tuple=False).T
            x = np.concatenate((box[i], x[i, j + 5, None], j[:, None].float()), 1)
        else:  # best class only
            # print(x[:, 5:].max(1, keepdims=True))
            conf = x[:, 5:].max(axis=1, keepdims=True)
            j = x[:, 5:].argmax(axis=1, keepdims=True)
            x = np.concatenate((box, conf, j.astype(np.float32)), 1)[conf.reshape(-1) > conf_thres]

        # Filter by class
        if classes is not None:
            x = x[(x[:, 5:6] == np.array(classes)).any(1)]

        # Apply finite constraint
        # if not torch.isfinite(x).all():
        #     x = x[torch.isfinite(x).all(1)]

        # Check shape
        n = x.shape[0]  # number of boxes
        if not n:  # no boxes
            continue
        elif n > max_nms:  # excess boxes
            x = x[x[:, 4].argsort(descending=True)[:max_nms]]  # sort by confidence

        # Batched NMS
        c = x[:, 5:6] * (0 if agnostic else max_wh)  # classes
        boxes, scores = x[:, :4] + c, x[:, 4]  # boxes (offset by class), scores
        i = numpy_nms(boxes, scores, iou_thres)  # NMS
        if i.shape[0] > max_det:  # limit detections
            i = i[:max_det]
        # if merge and (1 < n < 3E3):  # Merge NMS (boxes merged using weighted mean)
        #     # update boxes as boxes(i,4) = weights(i,n) * boxes(n,4)
        #     iou = box_iou(boxes[i], boxes) > iou_thres  # iou matrix
        #     weights = iou * scores[None]  # box weights
        #     x[i, :4] = torch.mm(weights, x[:, :4]).float() / weights.sum(1, keepdim=True)  # merged boxes
        #     if redundant:
        #         i = i[iou.sum(1) > 1]  # require redundancy

        output[xi] = x[i]
#        print(x[i])
        if (time.time() - t) > time_limit:
            print(f'WARNING: NMS time limit {time_limit}s exceeded')
            break  # time limit exceeded

#    print("[non_max_suppression.prediction] output:", output)
    return output


def show_seg_result(img, result):
    img_ori = img * 255.0
    color_area = np.zeros((result[0].shape[0], result[0].shape[1], 3), dtype=np.uint8) # (160, 320, 3)

    color_area[result[0] == 1] = [0, 255, 0]
    color_area[result[1] ==1] = [255, 0, 0]

    # convert to BGR
    color_seg = color_area[..., ::-1]

    color_mask = np.mean(color_seg, 2)
    # img = np.squeeze(img_ori, axis=0).copy()

    img[color_mask != 0] = img[color_mask != 0] * 0.5 + color_seg[color_mask != 0] * 0.5
    img = img.astype(np.uint8)
    # print(img.shape)
    return img, color_seg


def pil_resize(data, dsize):
    data = data.astype(np.uint8)
    return data
#    img = Image.fromarray(data)
#    img0 = img.resize(dsize, Image.Resampling.BILINEAR)
#    return np.array(img)

def box_iou(box1, box2):
    def box_area(box):
        # box = 4xn
        return (box[2] - box[0]) * (box[3] - box[1])

    area1 = box_area(box1.T)
    area2 = box_area(box2.T)

    # inter(N,M) = (rb(N,M,2) - lt(N,M,2)).clamp(0).prod(2)
    inter = (np.minimum(box1[:, None, 2:], box2[:, 2:]) - np.maximum(box1[:, None, :2], box2[:, :2])).clip(0).prod(2)
    return inter / (area1[:, None] + area2 - inter)  # iou = inter / (area1 + area2 - inter)

def xywh2xyxy(x):
    # Convert nx4 boxes from [x, y, w, h] to [x1, y1, x2, y2] where xy1=top-left, xy2=bottom-right
    y = np.copy(x)
    y[:, 0] = x[:, 0] - x[:, 2] / 2  # top left x
    y[:, 1] = x[:, 1] - x[:, 3] / 2  # top left y
    y[:, 2] = x[:, 0] + x[:, 2] / 2  # bottom right x
    y[:, 3] = x[:, 1] + x[:, 3] / 2  # bottom right y
    return y

def xyxy2xywh(x):
    # Convert nx4 boxes from [x1, y1, x2, y2] to [x, y, w, h] where xy1=top-left, xy2=bottom-right
    y = np.copy(x)
    y[:, 0] = (x[:, 0] + x[:, 2]) / 2  # x center
    y[:, 1] = (x[:, 1] + x[:, 3]) / 2  # y center
    y[:, 2] = x[:, 2] - x[:, 0]  # width
    y[:, 3] = x[:, 3] - x[:, 1]  # height
    return y

def driving_area_mask(input, shape4):
    x4 = np.array(input)
    input = x4.reshape(shape4[0], shape4[1], shape4[2], shape4[3])

    da_predict = input.squeeze(axis=0)
    ch, h, w = da_predict.shape
    da_predict = da_predict.argmax(axis=0)
    return da_predict

def lane_line_mask(input, shape4):
    x4 = np.array(input)
    input = x4.reshape(shape4[0], shape4[1], shape4[2], shape4[3])
    
    ll_predict = input.squeeze(axis=0)
    ch, h, w = ll_predict.shape
    ll_seg_mask = ll_predict[0].round()
    return ll_seg_mask

def infer(arr1, shape1, arr2, shape2, arr3, shape3):
    print('infer')
        
    x1 = np.array(arr1)
#    print(x1)
    y1 = x1.reshape(shape1[0], shape1[1], shape1[2], shape1[3])

    x2 = np.array(arr2)
#    print(x2)
    y2 = x2.reshape(shape2[0], shape2[1], shape2[2], shape2[3])

    x3 = np.array(arr3)
#    print(x3)
    y3 = x3.reshape(shape3[0], shape3[1], shape3[2], shape3[3])

    YH = [y1, y2, y3]
    
    pred = split_for_trace_model(pred=YH, anchor_grid=anchor_grid)
#    print("pred:", pred, pred.shape)
#    print("pred end")
    out = non_max_suppression(pred)
#    print(len(out))
#    print("out end")
    return out

def test(det, arr1, arr2):
    da_seg_mask = np.array(arr1, dtype='int32')
    ll_seg_mask = np.array(arr2, dtype='float32')
#    print("da_seg_mask", da_seg_mask.shape, da_seg_mask.dtype)
#    print("ll_seg_mask", ll_seg_mask.shape, ll_seg_mask.dtype)
#    print("det", det)

    groi.reset()
    front_pnt = None
    depth_pnt = None
    n_lanes = None
    rects1 = list(det)
    rects = []
    for rc in rects1:
        a1 = np.array(rc, dtype=np.float32)
        rects.append(a1)
    # # print(rects)
    if len(rects):
#        print(type(rects), type(rects[0]), type(rects[0][0]))
        front_pnt, front_box, n_lanes = groi(rects, da_seg_mask, ll_seg_mask)
        depth_pnt = None
        if front_pnt:
            w = int(front_box[2] - front_box[0]) * options["roi_size"][1] / 320     # img.shape[1]
            h = int(front_box[3] - front_box[1]) * options["roi_size"][0] / 160     # img.shape[0]
            ratio = h / w
            target_height = options["obj"]["car"]["height"] if ratio <= 1.2 else options["obj"]["cv"]["height"]
            depth_pnt = cc_cfg["K_dst"][0, 0] * target_height / h
        # print(img.shape)
#        img, _ = show_seg_result(img, (da_seg_mask,ll_seg_mask))
    print("front_pnt:", front_pnt)
    print("depth_pnt:", depth_pnt)
    print("n_lanes:", n_lanes)
    return depth_pnt

def test2(arr1, shape1, arr2, shape2, arr3, shape3, arr4, shape4, arr5, shape5):
    try:
        out = infer(arr1, shape1, arr2, shape2, arr3, shape3)
        da_seg_mask = driving_area_mask(arr4, shape4)
        ll_seg_mask = lane_line_mask(arr5, shape5)
        return test(out[0], da_seg_mask, ll_seg_mask)
    except:
        print("test2 error")
    else:
        return 0

def convertimg(img, rect):
    return img[self.rect[0]:self.rect[2], self.rect[1]:self.rect[3], :]
