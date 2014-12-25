
//
// NALUnit.h
//
// Basic parsing of H.264 NAL Units
//
// Geraint Davies, March 2004
//
// Copyright (c) GDCL 2004-2008 http://www.gdcl.co.uk/license.htm



#pragma once

#ifndef WIN32
typedef unsigned char BYTE;
typedef unsigned long ULONG;
#ifndef NULL
#define NULL 0
#endif
#endif

class NALUnit
{
public:
    NALUnit();
	NALUnit(const BYTE* pStart, int len)
    {
        m_pStart = m_pStartCodeStart = pStart;
        m_cBytes = len;
        ResetBitstream();
    }
	virtual ~NALUnit() {}

	// assignment copies a pointer into a fixed buffer managed elsewhere. We do not copy the data
	NALUnit(const NALUnit& r)
	{
		m_pStart = r.m_pStart;
		m_cBytes = r.m_cBytes;
		ResetBitstream();
	}
	const NALUnit& operator=(const NALUnit& r)
	{
		m_pStart = r.m_pStart;
		m_cBytes = r.m_cBytes;
		ResetBitstream();
		return *this;
	}

    enum eNALType
    {
        NAL_Slice               = 1,
        NAL_PartitionA          = 2,
        NAL_PartitionB          = 3,
        NAL_PartitionC          = 4,
        NAL_IDR_Slice           = 5,
		NAL_SEI					= 6,
        NAL_Sequence_Params     = 7,
        NAL_Picture_Params      = 8,
		NAL_AUD					= 9,
    };

    // identify a NAL unit within a buffer.
    // If LengthSize is non-zero, it is the number of bytes
    // of length field we expect. Otherwise, we expect start-code
    // delimiters.
    bool Parse(const BYTE* pBuffer, int cSpace, int LengthSize, bool bEnd);
    
    eNALType Type()
    {
		if (m_pStart == NULL)
		{
			return eNALType(0);
		}
        return eNALType(m_pStart[0] & 0x1F);
    }
    
    int Length()
    {
        return m_cBytes;
    }

    const BYTE* Start()
    {
        return m_pStart;
    }

    // bitwise access to data
    void ResetBitstream();
    void Skip(int nBits);

    unsigned long GetWord(int nBits);
    unsigned long GetUE();
    long GetSE();
    BYTE GetBYTE();
    unsigned long GetBit();
	bool NoMoreBits()	{ return (m_idx >= m_cBytes) && (m_nBits == 0); }

	const BYTE* StartCodeStart()	{ return m_pStartCodeStart; }
    bool IsRefPic()
    {
        if (m_pStart && (m_pStart[0] & 0x60))
        {
            return true;
        }
        return false;
    }


private:
    bool GetStartCode(const BYTE*& pBegin, const BYTE*& pStart, int& cRemain);

private:
	const BYTE* m_pStartCodeStart;
    const BYTE* m_pStart;
    int m_cBytes;

    // bitstream access
    int m_idx;
    int m_nBits;
    BYTE m_byte;
    int m_cZeros;
};



// simple parser for the Sequence parameter set things that we need
class SeqParamSet
{
public:
    SeqParamSet();
    bool Parse(NALUnit* pnalu);
    int FrameBits() 
    {
        return m_FrameBits;
    }
    long EncodedWidth()
    {
        return m_cx;
    }
    long EncodedHeight()
    {
        return m_cy;
    }
#ifdef WIN32
    long CroppedWidth()
    {
        if (IsRectEmpty(&m_rcFrame))
        {
            return EncodedWidth();
        }
        return m_rcFrame.right - m_rcFrame.left;
    }
    long CroppedHeight()
    {
        if (IsRectEmpty(&m_rcFrame))
        {
            return EncodedHeight();
        }
        return m_rcFrame.bottom - m_rcFrame.top;
    }
    RECT* CropRect()
    {
        return &m_rcFrame;
    }
#endif
	bool Interlaced()
	{
		return !m_bFrameOnly;
	}
	unsigned int Profile()	{ return m_Profile; }
	unsigned int Level()	{ return m_Level; }
	BYTE Compat()	{ return m_Compatibility; }
	NALUnit* NALU() {return &m_nalu; }
    int POCLSBBits()    { return m_pocLSBBits;  }
    int POCType()       { return m_pocType; }
    
private:
    NALUnit m_nalu;
    int m_FrameBits;
    long m_cx;
    long m_cy;
#ifdef WIN32
    RECT m_rcFrame;
#endif
	bool m_bFrameOnly;

	int m_Profile;
	int m_Level;
	BYTE m_Compatibility;
    int m_pocType;
    int m_pocLSBBits;
};

// extract frame num from slice headers
class SliceHeader
{
public:

    bool Parse(NALUnit* pnalu, SeqParamSet* sps, bool bDeltaPresent);
    int FrameNum()
    {
        return m_framenum;
    }
    bool IsField()  { return m_bField; }
    bool IsBottom() { return m_bBottom; }
    int Delta()     { return m_pocDelta; }
    int POCLSB()    { return m_poc_lsb; }

private:
    int m_framenum;
    int m_nBitsFrame;
    bool m_bFrameOnly;
    
    bool m_bField;
    bool m_bBottom;
    int m_pocDelta;
    int m_poc_lsb;
};

// SEI message structure
class SEIMessage
{
public:
	SEIMessage(NALUnit* pnalu);
	int Type()					{ return m_type; }
	int Length()				{ return m_length; }
	const BYTE* Payload()		{ return m_pnalu->Start() + m_idxPayload; }
private:
	NALUnit* m_pnalu;
	int m_type;
	int m_length;
	int m_idxPayload;
};

// avcC structure from MP4
class avcCHeader
{
public:
    avcCHeader(const BYTE* header, int cBytes);
    NALUnit* sps()      { return &m_sps; }
    NALUnit* pps()      { return &m_pps; }
	long lengthSize()	{ return m_lengthSize; }
    
private:
	long m_lengthSize;
    NALUnit m_sps;
    NALUnit m_pps;
};

// NB this is NOT general-purpose. This
// implements only the details that I've seen in
// iOS encoding (poc type 0 only, and no checks for mmco 5)
class POCState
{
public:
    POCState();
    
    void SetHeader(avcCHeader* avc);
    bool GetPOC(NALUnit* nal, int* pPOC);
    int getFrameNum()
    {
        return m_frameNum;
    }
    int getLastLSB()
    {
        return m_lastlsb;
    }
private:
    int m_prevLSB;
    int m_prevMSB;
    avcCHeader* m_avc;
    SeqParamSet m_sps;
    bool m_deltaPresent;
    int m_frameNum;
    int m_lastlsb;
};


